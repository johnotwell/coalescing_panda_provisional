class CoalescingPanda::Workers::AccountMiner
  SUPPORTED_MODELS = [:courses, :users]
  COMPLETED_STATUSES = ['Completed', 'Error']
  RUNNING_STATUSES = ['Queued', 'Started']

  attr_accessor :options, :account, :batch, :user_ids, :course_ids

  def initialize(account, options = [])
    @account = account
    @options = options
    @batch = setup_batch
    @user_ids = []
    @course_ids = []
  end

  def setup_batch
    batch = account.canvas_batches.where(context: account).first
    if batch.present? and RUNNING_STATUSES.include?(batch.status)
      batch
    else
      batch = account.canvas_batches.create(context: account, status: "Queued")
    end
    batch.update_attributes(options: options)
    batch
  end

  def api_client
    @api_client ||= Bearcat::Client.new(prefix: account.settings[:base_url], token: account.settings[:account_admin_api_token])
  end

  def start(forced = false)
    unless forced
      return unless batch.status == 'Queued' # don't start if there is already a running job
      return unless should_download?
    end

    begin
      batch.update_attributes(status: "Started", percent_complete: 0)
      index = 1
      SUPPORTED_MODELS.each do |model_key|
        next unless options.include?(model_key)
        process_api_data(model_key.to_sym)
        percent_complete = (index/(options.count.nonzero? || 1).to_f * 100).round(1)
        batch.update_attributes(percent_complete: percent_complete)
        index += 1
      end
      batch.update_attributes(status: "Completed", percent_complete: 100)
    rescue => e
      batch.update_attributes(status: "Error", message: e.message)
    end
  end
  handle_asynchronously :start

  def should_download?
    return true unless account.settings[:canvas_download_interval].present?
    return true unless last_completed_batch = account.canvas_batches.where(context: account, status: 'Completed').order('updated_at ASC').first
    should_download = last_completed_batch.updated_at < Time.zone.now - account.settings[:canvas_download_interval].minutes
    batch.update_attributes(status: 'Canceled') unless should_download
    should_download
  end

  def process_api_data(key)
    case key
    when :courses
      collection = api_client.account_courses(account.canvas_account_id).all_pages!
      sync_courses(collection)
    when :users
      collection = api_client.list_users(account.canvas_account_id).all_pages!
      sync_users(collection)
    else
      raise "API METHOD DOESN'T EXIST"
    end
  end

  def sync_courses(collection)
    collection.each do |values|
      begin
        values['canvas_course_id'] = values["id"].to_s
        course = account.courses.where(canvas_course_id: values['canvas_course_id']).first_or_initialize
        course.coalescing_panda_lti_account_id = account.id
        course.assign_attributes(standard_attributes(course, values))
        course.sis_id = values['sis_course_id'].to_s
        course.save(validate: false)
        course_ids << course.id
      rescue => e
        Rails.logger.error "Error syncing course: #{values} Error: #{e}"
      end
    end
    removed_courses = account.courses.where.not(id: course_ids)
    account.submissions.where(coalescing_panda_course_id: removed_courses.map(&:id)).destroy_all
    removed_courses.each do |course|
      course.enrollments.destroy_all
    end
  removed_courses.destroy_all
  end

  def sync_users(collection)
    collection.each do |values|
      begin
        values['canvas_user_id'] = values["id"].to_s
        user = account.users.where(canvas_user_id: values['canvas_user_id']).first_or_initialize
        user.coalescing_panda_lti_account_id = account.id
        user.assign_attributes(standard_attributes(user, values))
        user.sis_id = values['sis_user_id'].to_s
        user.save(validate: false)
        user_ids << user.id
      rescue => e
        Rails.logger.error "Error syncing user: #{values} Error: #{e}"
      end
    end
    removed_users = account.users.where.not(id: user_ids)
    account.submissions.where(coalescing_panda_user_id: removed_users.map(&:id)).destroy_all
    removed_users.each do |user|
      user.enrollments.destroy_all
    end
    removed_users.destroy_all
  end

  def standard_attributes(record, attributes)
    new_attributes = attributes.dup
    new_attributes.delete('id')
    new_attributes.delete_if { |key, value| !record.attributes.include?(key) }
  end
end