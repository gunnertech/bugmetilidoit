module AssignedTasksHelper
  def duration_with_minutes(time)
    "#{time} #{t("minutes")}"
  end
end
