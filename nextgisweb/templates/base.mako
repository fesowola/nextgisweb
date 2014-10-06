<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<%
    import json
    from bunch import Bunch
%>
<head>

    <title>
        %if hasattr(self, 'title'):
            ${self.title()} :: 
        %endif

        ${request.env.core.settings['system.name']}
    </title>

    <link href="${request.static_url('nextgisweb:static/css/pure-0.4.2-min.css')}"
        rel="stylesheet" type="text/css"/>

    <link href="${request.static_url('nextgisweb:static/css/layout.css')}"
        rel="stylesheet" type="text/css"/>

    <link href="${request.static_url('nextgisweb:static/css/default.css')}"
        rel="stylesheet" type="text/css" media="screen"/>

    <link href="${request.static_url('nextgisweb:static/css/icon.css')}"
        rel="stylesheet" type="text/css" media="screen"/>
 
    <link href="${request.route_url('amd_package', subpath='dijit/themes/claro/claro.css')}"
        rel="stylesheet" media="screen"/>

    <script type="text/javascript">
        var ngwConfig = {
            applicationUrl: ${request.application_url | json.dumps, n},
            assetUrl: ${request.static_url('nextgisweb:static/') | json.dumps, n },
            amdUrl: ${request.route_url('amd_package', subpath="") | json.dumps, n}
        };

        var dojoConfig = {
            async: true,
            isDebug: true,
            baseUrl: ${request.route_url('amd_package', subpath="dojo") | json.dumps, n}
        };
    </script>

    <script src="${request.route_url('amd_package', subpath='dojo/dojo.js')}"></script>

    %if hasattr(self, 'assets'):
        ${self.assets()}
    %endif

    %if hasattr(self, 'head'):
        ${self.head()}
    %endif

</head>

<body class="claro">

    %if not custom_layout:

        <div id="super-header" class="pure-g super-header">
            <div class="pure-u-1-2">
                <div class="logo"><img src="${request.static_url('nextgisweb:static/img/logo.jpg')}"></div>
                <div class="ministry-agency-container">
                    <div class="ministry-name">Министерство транспорта Российской Федерации</div>
                    <div class="agency-name">Федеральное дорожное агентство</div>
                </div>
            </div>
            <div class="pure-u-1-2">
                <div class="system-name">
                    Система оперативного мониторинга транспортно-эксплуатационного состояния 
                    федеральных автомобильных дорог
                </div>
            </div>
        </div>

        <div id="header" class="header">

            <div class="home-menu pure-menu pure-menu-open pure-menu-horizontal">
                
                <ul class="lmenu">

                    <li><a href="${request.application_url}">${request.env.core.settings['system.full_name']}</a></li>
                    <span class="separator"></span>
                    <li><a href="${request.route_url('resource.root')}">Ресурсы</a></li>
                    %if request.user.is_administrator:
                        <span class="separator"></span>
                        <li><a href="${request.route_url('pyramid.control_panel')}">Панель управления</a></li>
                    %endif

                </ul>

                <ul class="rmenu">

                    %if request.user.keyname == 'guest':
                        <li><a href="${request.route_url('auth.login')}">Вход</a></li>
                    %else:
                        <li class="user"><a href="#">${request.user}</a></li>
                        <li>|</li>
                        <li class="help"><a href="${request.route_url('pyramid.help_page')}">&nbsp;</a></li>
                        <li>|</li>
                        <li><a href="${request.route_url('auth.logout')}">Выход</a></li>
                    %endif

                </ul>
            </div>

        </div>

        %if hasattr(next, 'title_block'):
            <div id="title" class="title">
                ${next.title_block()}
            </div>
        %elif hasattr(next, 'title'):
            <div id="title" class="title">
                <h1>${next.title()}</h1>
            </div>
        %elif title:
            <div id="title" class="title">
                <h1>${title}</h1>
            </div>
        %endif

        <div id="content-wrapper"
            class="content-wrapper ${'maxwidth' if maxwidth else ''} ${'content-maxheight' if maxheight else ''}">

            <div class="content expand">

                <div class="pure-g expand">

                    %if obj and hasattr(obj,'__dynmenu__'):
                        <%
                            has_dynmenu = True
                            dynmenu = obj.__dynmenu__
                            dynmenu_kwargs = Bunch(obj=obj, request=request)
                        %>
                    %elif 'dynmenu' in context.keys():
                        <%
                            has_dynmenu = True
                            dynmenu = context['dynmenu']
                            dynmenu_kwargs = context.get('dynmenu_kwargs', Bunch(request=request))
                        %>
                    %else:
                        <% has_dynmenu = False %>
                    %endif
                
                    <div class="pure-u-${"20-24" if has_dynmenu else "1"} expand">
                        %if hasattr(next, 'body'):
                            ${next.body()}
                        %endif
                    </div>

                    %if has_dynmenu:
                        <div class="pure-u-4-24"><div style="padding-left: 1em;">
                            <%include file="dynmenu.mako" args="dynmenu=dynmenu, args=dynmenu_kwargs" />
                        </div></div>
                    %endif

                </div>

            </div>

        </div>

    %else:
    
        ${next.body()}
    
    %endif


    %if maxheight:

        <script type="text/javascript">

            require(["dojo/dom", "dojo/dom-style", "dojo/dom-geometry", "dojo/on", "dojo/domReady!"],
            function (dom, domStyle, domGeom, on) {
                var content = dom.byId("content-wrapper"),
                    header = [ ];

                for (var id in {"super-header": true, "header": true, "title": true}) {
                    var node = dom.byId(id);
                    if (node) { header.push(node) }
                }

                function resize() {
                    var h = 0;
                    for (var i = 0; i < header.length; i++) {
                        var n = header[i], cs = domStyle.getComputedStyle(n);
                        h = h + domGeom.getMarginBox(n, cs).h;
                    }
                    domStyle.set(content, "top", h + "px");
                }

                resize();

                on(window, 'resize', resize);
            });

        </script>

    %endif

</body>

</html>