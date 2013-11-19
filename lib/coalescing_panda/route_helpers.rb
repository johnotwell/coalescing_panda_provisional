module CoalescingPanda
  module RouteHelpers
    def lti_nav(nav, *rest, &block)
      base_path = Rails.application.routes.named_routes[:coalescing_panda].path.spec
      raise LtiNavigationInUse.new('CoalescingPanda must be mounted before defining lti_nav routes') if base_path.blank?
      valid_options = [:course, :user, :account, :editor, :external_tool]
      if rest.empty? && nav.is_a?(Hash)
        options = nav
        nav, to = options.find {|name, _value| valid_options.include? name}
        options[:to] = to
        options.delete(nav)
      else
        options = rest.pop || {}
      end
      lti_options = options.delete(:lti_options) || {}
      path = "#{base_path}/#{nav.to_s}"
      lti_options[:url] = path.split('/').reject(&:empty?).join('_')
      post path, options, &block
      CoalescingPanda::lti_navigation(nav, lti_options)
    end

    def lti_mount(app, options = nil)
      CoalescingPanda.lti_options = options && options.delete(:lti_options)
      mount(app, options)
    end

  end
end