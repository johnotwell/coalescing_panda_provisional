module CoalescingPanda
  class Course < ActiveRecord::Base
    belongs_to :account, foreign_key: :coalescing_panda_lti_account_id, class_name: 'CoalescingPanda::LtiAccount'
    belongs_to :term, foreign_key: :coalescing_panda_term_id, class_name: 'CoalescingPanda::Term'
    has_many :sections, foreign_key: :coalescing_panda_course_id, class_name: 'CoalescingPanda::Section'
    has_many :enrollments, through: :sections
    has_many :assignments, foreign_key: :coalescing_panda_course_id, class_name: 'CoalescingPanda::Assignment'
    has_many :submissions, through: :assignments
    has_many :users, through: :sections, source: :users, class_name: 'CoalescingPanda::User'
  end
end