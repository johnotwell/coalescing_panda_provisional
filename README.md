Coalescing Panda
=

Coalescing Panda is a rails engine that provides OAuth2 authentication, and simplifies LTI tools for Canvas.



Configuration
-
---

Add the following line to routes.rb file. passing in the title to lti_options.

    mount CoalescingPanda::Engine, at: "/lti"

in your routes file below where you mounted your engine use the following to specify custom navigation:

    lti_nav course: 'controller#action', lti_options:{enabled: true, text: 'course link title', visibility: 'admins'}


    lti_nav account: 'controller#action', lti_options:{enabled: true, text: 'admin link title'}

    lti_nav :navigation_type: 'controller#action', lti_options:{'hash of options to use for the navigation'}

The paths for each of the navigation items will be the lti_mount path followed by the navigation symbol you provide, i.e. "lti_nav :account" will be defined as lti_mount_path/account


The tool will generate XML that can be used to configure the tool in Canvas. The url for the config will be the lti_mount path followed by config. i.e:

    /lti/config

An initializer will also need to be created to populate the options for lti tool and lti navigation. This can be done by creating an initializer
in the intializers folder in your rails project, and includeing the following:

    CoalescingPanda.lti_options= {title:'LTI Tool Title'}
    CoalescingPanda.stage_navigation(:course, {enabled: true, text: 'course link title', visibility: 'admins'})
    CoalescingPanda.stage_navigation(:admin, {enabled: true, text: 'admin link title', visibility: 'admins'})

### DB Setup

populate the "CoalescingPanda::LtiAccount" model for each oauth key/secret pair you are using. Optionally if you want to use Oauth2 you can fill those values as well

###LTI Authentication
Oauth singatures can be validated by using lti_authorize as a before filter

    before_action :lti_authorize!, only: [:course]

or to include role checking

    before_action(:only => [:course]) { |c| c.lti_authorize!(:admin, :teacher) }

###OAuth2
To use OAuth2 create a before filter in your controller with :canvas_oath2 as the method, i.e:

    before_action :canvas_oauth2, :only => [:course]


####Enviroment Variables
The following environment variable can be set to use http instead of https

    OAUTH_PROTOCOL=http


#### SAFARI SESSION FIX
When redirecting from the lti landing controller to the new application, the session will be lost if the new application is opened in an iFrame. In order to work around this problem, do the following:

1) before you redirect add
    token = CoalescingPanda::Session.create_from_session(session)
    redirect_to conferences_path(restore_session_token: token)
2) then in the applications application_controller.rb, add the following code snippet

    before_filter :restore_session

    def restore_session
      CoalescingPanda::Session.restore_from_token(params[:restore_session_token], session) if params[:restore_session_token].present?
    end