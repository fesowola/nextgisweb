# -*- coding: utf-8 -*-
from __future__ import unicode_literals, print_function, absolute_import
from collections import OrderedDict
from passlib.hash import sha256_crypt
import sqlalchemy as sa
import sqlalchemy.orm as orm

from ..models import declarative_base


Base = declarative_base()

tab_group_user = sa.Table(
    'auth_group_user', Base.metadata,
    sa.Column(
        'group_id', sa.Integer,
        sa.ForeignKey('auth_group.principal_id'),
        primary_key=True
    ),
    sa.Column(
        'user_id', sa.Integer,
        sa.ForeignKey('auth_user.principal_id'),
        primary_key=True
    )
)


class Principal(Base):
    __tablename__ = 'auth_principal'

    id = sa.Column(sa.Integer, sa.Sequence('principal_seq'), primary_key=True)
    cls = sa.Column(sa.Unicode(1), nullable=False)
    system = sa.Column(sa.Boolean, nullable=False, default=False)
    display_name = sa.Column(sa.Unicode, nullable=False)
    description = sa.Column(sa.Unicode)

    __mapper_args__ = dict(
        polymorphic_on=cls,
        with_polymorphic='*'
    )


class User(Principal):
    __tablename__ = 'auth_user'

    principal_id = sa.Column(
        sa.Integer, sa.Sequence('principal_seq'),
        sa.ForeignKey(Principal.id), primary_key=True)
    keyname = sa.Column(sa.Unicode, unique=True)
    superuser = sa.Column(sa.Boolean, nullable=False, default=False)
    disabled = sa.Column(sa.Boolean, nullable=False, default=False)
    password_hash = sa.Column(sa.Unicode)

    __mapper_args__ = dict(polymorphic_identity='U')

    principal = orm.relationship(Principal)

    def __init__(self, password=None, **kwargs):
        super(Principal, self).__init__(**kwargs)
        if password:
            self.password = password

    def __unicode__(self):
        return self.display_name

    def compare(self, other):
        """ Compare two users regarding special users """

        # If neither user is special use regular comparison
        if not self.system and not other.system:
            return self.principal_id == other.principal_id

        elif self.system:
            a, b = self, other

        elif other.system:
            a, b = other, self

        # Now a - special user, b - common

        if a.keyname == 'everyone':
            return True

        elif a.keyname == 'authenticated':
            return b.keyname != 'guest'

        elif b.keyname == 'authenticated':
            return a.keyname != 'guest'

        else:
            return a.principal_id == b.principal_id and a.principal_id is not None

    @property
    def is_administrator(self):
        """ Is user member of 'administrators' """
        if self.principal_id is None:
            return False

        # To reduce number of DB requests, cache
        # 'administrators' group in the instance
        if not hasattr(self, '_admins'):
            self._admins = Group.filter_by(keyname='administrators').one()

        return any([user for user in self._admins.members if user.principal_id == self.principal_id])

    @property
    def password(self):
        return PasswordHashValue(self.password_hash)

    @password.setter # NOQA
    def password(self, value):
        self.password_hash = sha256_crypt.encrypt(value)

    def serialize(self):
        return OrderedDict((
            ('id', self.id),
            ('system', self.system),
            ('display_name', self.display_name),
            ('description', self.description),
            ('keyname', self.keyname),
            ('superuser', self.superuser),
            ('disabled', self.disabled),
            ('member_of', map(lambda g: g.id, self.member_of))
        ))

    def deserialize(self, data):
        attrs = ('display_name', 'description', 'keyname',
                 'superuser', 'disabled', 'password')
        for a in attrs:
            if a in data:
                setattr(self, a, data[a])

        if 'member_of' in data:
            self.member_of = list(map(
                lambda gid: Group.filter_by(id=gid).one(),
                data['member_of']))


class Group(Principal):
    __tablename__ = 'auth_group'

    principal_id = sa.Column(
        sa.Integer, sa.Sequence('principal_seq'),
        sa.ForeignKey(Principal.id), primary_key=True)
    keyname = sa.Column(sa.Unicode, unique=True)
    register = sa.Column(sa.Boolean, nullable=False, default=False)

    members = orm.relationship(
        User, secondary=tab_group_user,
        backref=orm.backref('member_of'))

    __mapper_args__ = dict(polymorphic_identity='G')

    principal = orm.relationship(Principal)

    def __unicode__(self):
        return self.display_name

    def is_member(self, user):
        if self.keyname == 'authorized':
            return user is not None and user.keyname != 'guest'

        elif self.keyname == 'everyone':
            return user is not None

        else:
            return user in self.members

    def serialize(self):
        return OrderedDict((
            ('id', self.id),
            ('system', self.system),
            ('display_name', self.display_name),
            ('description', self.description),
            ('keyname', self.keyname),
            ('register', self.register),
            ('members', map(lambda u: u.id, self.members))
        ))

    def deserialize(self, data):
        attrs = ('display_name', 'description', 'keyname', 'register')
        for a in attrs:
            if a in data:
                setattr(self, a, data[a])

        if 'members' in data:
            self.members = list(map(
                lambda uid: User.filter_by(id=uid).one(),
                data['members']))


class PasswordHashValue(object):
    """ Automatic password hashes comparison class """
    def __init__(self, value):
        self.value = value

    def __eq__(self, other):
        if self.value is None:
            return False
        elif isinstance(other, basestring):
            return sha256_crypt.verify(other, self.value)
        else:
            raise NotImplemented


class UserDisabled(Exception):
    """ Requested user is blocked """
