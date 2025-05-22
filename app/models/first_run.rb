class FirstRun
  def self.create!(user_attributes)
    user = User.member.create!(user_attributes)

    Account.create!(name: "Fizzy")
    Closure::Reason.create_defaults
    Collection.create!(name: "Cards", creator: user, all_access: true)

    workflow = Workflow.create!(name: "Basic workflow")
    Collection.first.update!(workflow: workflow)
    user
  end
end
