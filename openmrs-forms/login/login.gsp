<%
    ui.includeFragment("appui", "standardEmrIncludes")
    ui.includeJavascript("appui", "jquery.min.js")
    ui.includeJavascript("appui", "popper.min.js")
    ui.includeJavascript("appui", "bootstrap.min.js")

    def facilityMap = [:]
    if (showSessionLocations) {
        locations.each { loc ->
            def facilityName = loc.parentLocation ? ui.format(loc.parentLocation) : 'Unknown Facility'
            def facilityId = loc.parentLocation ? loc.parentLocation.id : 0
            if (!facilityMap.containsKey(facilityId)) {
                facilityMap[facilityId] = [name: facilityName, units: []]
            }
            facilityMap[facilityId].units.add(loc)
        }
        facilityMap.each { k, v -> v.units.sort { ui.format(it) } }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>${ ui.message("referenceapplication.login.title") }</title>
    <link rel="shortcut icon" type="image/ico" href="/${ ui.contextPath() }/images/openmrs-favicon.ico"/>
    <link rel="icon" type="image/png\" href="/${ ui.contextPath() }/images/openmrs-favicon.png"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <% ui.includeCss("appui", "bootstrap.min.css") %>
    <% ui.includeCss("login.css") %>
    <style>
        .login-step-header {
            font-size: 1.05em;
            font-weight: 600;
            margin-bottom: 12px;
            color: #555;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .login-step-header .step-num {
            display: inline-block;
            background: #2563eb;
            color: #fff;
            width: 22px;
            height: 22px;
            border-radius: 50%;
            text-align: center;
            line-height: 22px;
            font-size: 0.82em;
            margin-right: 6px;
            vertical-align: middle;
        }
        .facility-list, .unit-list {
            list-style: none;
            padding: 0;
            margin: 0 0 16px 0;
        }
        .facility-list li, .unit-list li {
            cursor: pointer;
            border: 2px solid #d1d5db;
            border-radius: 8px;
            padding: 12px 16px;
            margin-bottom: 8px;
            transition: all 0.15s;
            background: #fff;
            font-size: 1em;
        }
        .facility-list li:hover, .unit-list li:hover {
            border-color: #2563eb;
            background: #eff6ff;
        }
        .facility-list li.selected, .unit-list li.selected {
            border-color: #2563eb;
            background: #dbeafe;
            font-weight: 600;
        }
        .unit-list li {
            display: none;
        }
        .unit-list li.visible {
            display: block;
        }
        #facilityStep, #unitStep {
            margin-bottom: 12px;
        }
        #unitStep {
            display: none;
        }
        #unitStep.active {
            display: block;
        }
        .facility-selected-label {
            font-size: 0.92em;
            color: #2563eb;
            margin-bottom: 10px;
            padding: 6px 10px;
            background: #eff6ff;
            border-radius: 6px;
            display: none;
        }
        .facility-selected-label strong {
            display: inline;
        }
        .change-facility {
            text-decoration: underline;
            cursor: pointer;
            margin-left: 10px;
            color: #6b7280;
            font-weight: 400;
            font-size: 0.9em;
        }
        .change-facility:hover { color: #2563eb; }
    </style>
    ${ ui.resourceLinks() }
</head>
<body>
<script type="text/javascript">
    var OPENMRS_CONTEXT_PATH = '${ ui.contextPath() }';
</script>

<script type="text/javascript">
    jQuery(function () {
        jQuery("#togglePassword").click(function () {
            var pwdIcon = jQuery(this);
            pwdIcon.toggleClass("fa-eye fa-eye-slash");
            var type = pwdIcon.hasClass("fa-eye-slash") ? "text" : "password";
            jQuery("#password").attr("type", type);
        });
    });
</script>

<% if(showSessionLocations) { %>
<script type="text/javascript">
    jQuery(function() {
        var selectedFacility = null;

        updateSelectedOption = function() {
            jQuery('.unit-list li').removeClass('selected');
            var sessionLocationVal = jQuery('#sessionLocationInput').val();
            if(sessionLocationVal != null && sessionLocationVal != "" && sessionLocationVal != 0){
                jQuery('.unit-list li[value|=' + sessionLocationVal + ']').addClass('selected');
            }
        };

        /* --- Facility Step --- */
        jQuery('.facility-list li').click(function() {
            var facilityId = jQuery(this).attr('data-facility-id');
            selectedFacility = facilityId;
            jQuery('.facility-list li').removeClass('selected');
            jQuery(this).addClass('selected');
            jQuery('.facility-selected-label').html(
                '<strong>' + jQuery(this).text() + '</strong>' +
                '<span class="change-facility">Change facility</span>'
            ).show();
            jQuery('#unitStep').addClass('active');
            jQuery('.unit-list li').removeClass('visible');
            jQuery('.unit-list li[data-facility-id="' + facilityId + '"]').addClass('visible');
            updateSelectedOption();
        });

        jQuery('.facility-selected-label').on('click', '.change-facility', function(e) {
            e.stopPropagation();
            selectedFacility = null;
            jQuery('.facility-list li').removeClass('selected');
            jQuery('.facility-selected-label').hide();
            jQuery('#unitStep').removeClass('active');
            jQuery('.unit-list li').removeClass('visible selected');
            jQuery('#sessionLocationInput').val('');
        });

        /* --- Unit Step --- */
        jQuery('.unit-list li').click(function() {
            jQuery('.unit-list li').removeClass('selected');
            jQuery(this).addClass('selected');
            jQuery('#sessionLocationInput').val(jQuery(this).attr('value'));
        });
        jQuery('.unit-list li').focus(function() {
            jQuery('.unit-list li').removeClass('selected');
            jQuery(this).addClass('selected');
            jQuery('#sessionLocationInput').val(jQuery(this).attr('value'));
        });

        jQuery('.unit-list li').keyup(function(e) {
            var key = e.which || e.keyCode;
            if (key === 13) {
                jQuery('#login-form').submit();
            }
        });

        jQuery('#loginButton').click(function(e) {
            var sessionLocationVal = jQuery('#sessionLocationInput').val();
            if (!sessionLocationVal) {
                jQuery('#sessionLocationError').show();
                e.preventDefault();
            }
        });

        updateSelectedOption();
    });
</script>
<% } %>

<script type="text/javascript">
    jQuery(function() {
        var cannotLoginController = emr.setupConfirmationDialog({
            selector: '#cannotLoginPopup',
            actions: {
                confirm: function() {
                    cannotLoginController.close();
                }
            }
        });

		jQuery('#username').focus();
        jQuery('a#cantLogin').click(function() {
            cannotLoginController.show();
        });

        pageReady = true;
    });
</script>

<script type="text/javascript">
    jq(document).ready(function () {
        if(jq("#clientTimezone").length){
            jq("#clientTimezone").val(Intl.DateTimeFormat().resolvedOptions().timeZone)
        }
    });
</script>

<div id="content" class="container-fluid">
    <div class= "row">
        <div class="col-12 col-sm-12 col-md-12 col-lg-12">
            ${ ui.includeFragment("referenceapplication", "infoAndErrorMessages") }
        </div>
    </div>
    <div class= "row">
        <div class="col-12 col-sm-12 col-md-12 col-lg-12">
            <header>
                <div class="logo">
                    <a href="${ui.pageLink("referenceapplication", "home")}">
                        <img src="${ui.resourceLink("referenceapplication", "images/openMrsLogo.png")}"/>
                    </a>
                </div>
            </header>
        </div>
    </div>
    <div class= "row">
        <div class="col-12 col-sm-12 col-md-12 col-lg-12">
            <div id="body-wrapper">
                <div id="content">
                    <form id="login-form" method="post" autocomplete="off">
                        <fieldset class="border p-2">

                            <legend class="w-auto">
                                <i class="icon-lock small"></i>
                                ${ ui.message(selectLocation ? "referenceapplication.login.sessionLocation" : "referenceapplication.login.loginHeading") }
                            </legend>

                            <% if(!selectLocation) { %>
                            <p class="left">
                                <label for="username">
                                    ${ ui.message("referenceapplication.login.username") }:
                                </label>
                                <input class="form-control form-control-sm form-control-lg form-control-md" id="username" type="text" name="username" placeholder="${ ui.message("referenceapplication.login.username.placeholder") }"/>
                            </p>

                            <p class="left">
                                <label for="password">
                                    ${ ui.message("referenceapplication.login.password") }:
                                </label>
                                <input class="form-control form-control-sm form-control-lg form-control-md" id="password" type="password" name="password" placeholder="${ ui.message("referenceapplication.login.password.placeholder") }"/>
                                <i class="fa fa-eye" id="togglePassword"></i>
                            </p>
                            <% } %>

                            <% if(showSessionLocations) { %>
                            <p class="clear" style="margin-top:14px;">
                                <span class="location-error" id="sessionLocationError" style="display:none">${ui.message("referenceapplication.login.error.locationRequired")}</span>
                            </p>

                            <% if(!facilityMap.isEmpty()) { %>
                            <div id="facilityStep">
                                <div class="login-step-header"><span class="step-num">1</span> Health Facility</div>
                                <ul class="facility-list">
                                    <% facilityMap.each { facilityId, facilityData -> %>
                                    <li data-facility-id="${facilityId}" tabindex="0">
                                        <i class="icon-hospital"></i> ${ui.encodeHtml(facilityData.name)}
                                    </li>
                                    <% } %>
                                </ul>
                            </div>

                            <div id="unitStep">
                                <div class="facility-selected-label"></div>
                                <div class="login-step-header"><span class="step-num">2</span> Unit / Department</div>
                                <ul class="unit-list">
                                    <% facilityMap.each { facilityId, facilityData -> %>
                                        <% facilityData.units.each { loc -> %>
                                        <li data-facility-id="${facilityId}" tabindex="0" value="${loc.id}">
                                            ${ui.encodeHtmlContent(ui.format(loc))}
                                        </li>
                                        <% } %>
                                    <% } %>
                                </ul>
                            </div>
                            <% } else { %>
                            <% // Fallback: flat list if locations have no parent %>
                            <div id="facilityStep">
                                <div class="login-step-header"><span class="step-num">1</span> Select Location</div>
                                <ul class="facility-list">
                                    <% locations.sort { ui.format(it) }.each { %>
                                    <li data-facility-id="${it.parentLocation?.id ?: 0}" tabindex="0" value="${it.id}">
                                        ${ui.encodeHtmlContent(ui.format(it))}
                                    </li>
                                    <% } %>
                                </ul>
                            </div>
                            <% } %>

                            <input type="hidden" id="sessionLocationInput" name="sessionLocation"
                                <% if (lastSessionLocation != null) { %> value="${lastSessionLocation.id}" <% } %> />
                            <% if (ui.convertTimezones()) { %>
                                <input type="hidden" id="clientTimezone" name="clientTimezone">
                            <%} %>
                            <% } %>
                            <p>
                            <% if(selectLocation) {%>
                                <input id="cancelButton" class="btn cancel" type="button"
                                    onclick="javascript:window.location = '/${ contextPath }/logout'"
                                    value="${ ui.message("general.cancel") }" />&nbsp;&nbsp;
                            <% } %>
                                <input id="loginButton" class="btn ${ ui.message(selectLocation ? "btn-success" : "confirm") }" type="submit"
                                    value="${ ui.message(selectLocation ? "general.done" : "referenceapplication.login.button") }"/>
                            </p>
                            <% if(!selectLocation) {%>
                            <p>
                                <a id="cantLogin" href="javascript:void(0)">
                                    <i class="icon-question-sign small"></i>
                                    ${ ui.message("referenceapplication.login.cannotLogin") }
                                </a>
                            </p>
                            <% } %>
                        </fieldset>
                        <input type="hidden" name="redirectUrl" value="${ui.encodeHtmlAttribute(redirectUrl)}" />

                    </form>
                </div>
            </div>
        </div>
    </div>
    <div class= "row">
        <div class="col-12 col-sm-12 col-md-12 col-lg-12">
            <div id="cannotLoginPopup" class="dialog" style="display: none">
                <div class="dialog-header">
                    <i class="icon-info-sign"></i>
                    <h3>${ ui.message("referenceapplication.login.cannotLogin") }</h3>
                </div>
                <div class="dialog-content">
                    <p class="dialog-instructions">${ ui.message("referenceapplication.login.cannotLoginInstructions") }</p>
                    <button class="confirm">${ ui.message("referenceapplication.okay") }</button>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
