<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=false; section>
  <#if section = "form">
    <link rel="stylesheet" href="${url.resourcesPath}/css/styles.css" />

    <div class="g6-page">
      <div class="g6-card">
        <div class="g6-top">
          <a class="g6-back" href="${url.loginUrl}">‹</a>

          <div class="g6-icon">
            <img src="${url.resourcesPath}/img/logo.svg" alt="Logo" />
          </div>

          <h1 class="g6-title">${msg("registerTitle")}</h1>
          <p class="g6-subtitle">PC Components Store - Create your account</p>
        </div>

        <#if message?has_content>
          <div class="g6-alert <#if message.type = 'success'>g6-alert-success<#elseif message.type = 'info'>g6-alert-info</#if>">
            ${kcSanitize(message.summary)?no_esc}
          </div>
        </#if>

        <form id="kc-register-form" action="${url.registrationAction}" method="post">
          <#-- First Name -->
          <div class="g6-field">
            <label for="firstName">${msg("firstName")}</label>
            <div class="g6-input">
              <input
                type="text"
                id="firstName"
                name="firstName"
                value="${(register.formData.firstName!'')}"
                placeholder="${msg("firstName")}"
                required
                autofocus
                autocomplete="given-name"
              />
              <span class="g6-inputIcon g6-mail"></span>
            </div>
          </div>

          <#-- Last Name -->
          <div class="g6-field">
            <label for="lastName">${msg("lastName")}</label>
            <div class="g6-input">
              <input
                type="text"
                id="lastName"
                name="lastName"
                value="${(register.formData.lastName!'')}"
                placeholder="${msg("lastName")}"
                required
                autocomplete="family-name"
              />
              <span class="g6-inputIcon g6-mail"></span>
            </div>
          </div>

          <#-- Email -->
          <div class="g6-field">
            <label for="email">${msg("email")}</label>
            <div class="g6-input">
              <input
                type="email"
                id="email"
                name="email"
                value="${(register.formData.email!'')}"
                placeholder="${msg("email")}"
                required
                autocomplete="email"
              />
              <span class="g6-inputIcon g6-mail"></span>
            </div>
          </div>

          <#-- Username (if not using email as username) -->
          <#if !realm.registrationEmailAsUsername>
            <div class="g6-field">
              <label for="username">${msg("username")}</label>
              <div class="g6-input">
                <input
                  type="text"
                  id="username"
                  name="username"
                  value="${(register.formData.username!'')}"
                  placeholder="${msg("username")}"
                  required
                  autocomplete="username"
                />
                <span class="g6-inputIcon g6-mail"></span>
              </div>
            </div>
          </#if>

          <#-- Password -->
          <#if passwordRequired??>
            <div class="g6-field">
              <label for="password">${msg("password")}</label>
              <div class="g6-input">
                <input
                  type="password"
                  id="password"
                  name="password"
                  placeholder="${msg("password")}"
                  required
                  autocomplete="new-password"
                />
                <span class="g6-inputIcon g6-lock"></span>
              </div>
            </div>

            <#-- Password Confirm -->
            <div class="g6-field">
              <label for="password-confirm">${msg("passwordConfirm")}</label>
              <div class="g6-input">
                <input
                  type="password"
                  id="password-confirm"
                  name="password-confirm"
                  placeholder="${msg("passwordConfirm")}"
                  required
                  autocomplete="new-password"
                />
                <span class="g6-inputIcon g6-lock"></span>
              </div>
            </div>
          </#if>

          <#-- Recaptcha if enabled -->
          <#if recaptchaRequired??>
            <div class="g6-field">
              <div class="g-recaptcha" data-size="compact" data-sitekey="${recaptchaSiteKey}"></div>
            </div>
          </#if>

          <button class="g6-btn" type="submit" name="register">${msg("doRegister")}</button>

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

          <div class="g6-bottom">
            <span>${msg("alreadyHaveAccount")}</span>
            <a class="g6-link" href="${url.loginUrl}">${msg("doLogIn")}</a>
          </div>
        </form>
      </div>
    </div>
  </#if>
</@layout.registrationLayout>
