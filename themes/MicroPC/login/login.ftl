<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=false; section>
  <#if section = "form">
    <link rel="stylesheet" href="${url.resourcesPath}/css/styles.css" />

    <div class="g6-page">
      <div class="g6-card">
        <div class="g6-top">
          <#if realm.internationalizationEnabled && locale.supported?size gt 1>
            <a class="g6-back" href="${url.loginUrl}">‹</a>
          </#if>

          <div class="g6-icon">
            <img src="${url.resourcesPath}/img/logo.svg" alt="Logo" />
          </div>

          <h1 class="g6-title">Login</h1>
          <p class="g6-subtitle">PC Components Store - Powering your performance</p>
        </div>

        <#if message?has_content>
          <div class="g6-alert <#if message.type = 'success'>g6-alert-success<#elseif message.type = 'info'>g6-alert-info</#if>">
            ${kcSanitize(message.summary)?no_esc}
          </div>
        </#if>

        <form id="kc-form-login" action="${url.loginAction}" method="post">
          <div class="g6-field">
            <label for="username">
              <#if !realm.loginWithEmailAllowed>
                ${msg("username")}
              <#elseif !realm.registrationEmailAsUsername>
                ${msg("usernameOrEmail")}
              <#else>
                ${msg("email")}
              </#if>
            </label>
            <div class="g6-input">
              <input
                id="username"
                name="username"
                type="text"
                autocomplete="username"
                value="${(login.username!'')}"
                placeholder="<#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>"
                required
                autofocus
              />
              <span class="g6-inputIcon g6-mail"></span>
            </div>
          </div>

          <div class="g6-field">
            <label for="password">${msg("password")}</label>
            <div class="g6-input">
              <input
                id="password"
                name="password"
                type="password"
                autocomplete="current-password"
                placeholder="${msg("password")}"
                required
              />
              <span class="g6-inputIcon g6-lock"></span>
            </div>
          </div>

          <div class="g6-row">
            <#if realm.rememberMe && !usernameEditDisabled??>
              <div class="g6-checkbox">
                <input
                  id="rememberMe"
                  name="rememberMe"
                  type="checkbox"
                  <#if login.rememberMe??>checked</#if>
                />
                <label for="rememberMe">${msg("rememberMe")}</label>
              </div>
            <#else>
              <span></span>
            </#if>

            <#if realm.resetPasswordAllowed>
              <a class="g6-link" href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a>
            </#if>
          </div>

          <button class="g6-btn" type="submit" name="login">${msg("doLogIn")}</button>

          <#-- Social providers -->
          <#if social.providers?? && (social.providers?size > 0)>
            <div class="g6-divider"><span>${msg("identity-provider-login-label")}</span></div>
            <div class="g6-social">
              <#list social.providers as p>
                <a class="g6-socialBtn g6-${p.alias?lower_case}" href="${p.loginUrl}" title="${p.displayName}">
                  <span class="g6-socialIcon"></span>
                  <span class="g6-socialText">${p.displayName}</span>
                </a>
              </#list>
            </div>
          </#if>

          <#if realm.registrationAllowed && !registrationDisabled??>
            <div class="g6-bottom">
              <span>${msg("noAccount")}</span>
              <a class="g6-link" href="${url.registrationUrl}">${msg("doRegister")}</a>
            </div>
          </#if>
        </form>
      </div>
    </div>
  </#if>
</@layout.registrationLayout>
