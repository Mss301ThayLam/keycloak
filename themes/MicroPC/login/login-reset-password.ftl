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

          <h1 class="g6-title">${msg("emailForgotTitle")}</h1>
          <p class="g6-subtitle">${msg("emailInstruction")}</p>
        </div>

        <#if message?has_content>
          <div class="g6-alert <#if message.type = 'success'>g6-alert-success<#elseif message.type = 'info'>g6-alert-info</#if>">
            ${kcSanitize(message.summary)?no_esc}
          </div>
        </#if>

        <form id="kc-reset-password-form" action="${url.loginAction}" method="post">
          <div class="g6-field">
            <label for="username">${msg("usernameOrEmail")}</label>
            <div class="g6-input">
              <input
                type="text"
                id="username"
                name="username"
                placeholder="${msg("usernameOrEmail")}"
                required
                autofocus
                autocomplete="username"
              />
              <span class="g6-inputIcon g6-mail"></span>
            </div>
          </div>

          <button class="g6-btn" type="submit">${msg("doSubmit")}</button>

          <div class="g6-bottom">
            <a class="g6-link" href="${url.loginUrl}">« ${msg("backToLogin")}</a>
          </div>
        </form>
      </div>
    </div>
  </#if>
</@layout.registrationLayout>
