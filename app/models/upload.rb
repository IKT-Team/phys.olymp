class Upload
  include ActiveModel::Model

  attr_accessor :secret, :solutions, :ips

  validates :user, presence: true

  def user
    @user ||= User.find_by secret: secret if secret.present?
  end

  def solutions_attributes= attributes
    attributes = attributes.values if attributes.is_a? Hash
    @solutions = attributes.map { Solution.new _1 }
  end

  def save
    solutions.each { _1.assign_attributes user: user, ips: ips }
    @solutions = solutions.filter { _1.file.present? }
    solutions.each &:save if valid?
  end

  def messages
    result = []
    result << { type: :error, text: 'Виберіть хоча б один файл!' } if solutions.blank?
    solutions.each_with_index do |solution, index|
      name = solution.task_display_name || index
      if solution.errors.blank? && solution.persisted?
        text = "#{name}: успішно завантажений на сервер"
        text << " (#{solution.upload_number} разів із #{solution.task_upload_limit})" if solution.upload_number > 1
        result << { type: :info, text: text }
      elsif solution.errors.blank?
        text = "#{name}: Помилка! Не вдалося завантажити файл на сервер!"
        result << { type: :error, text: text }
      else
        solution.errors.full_messages.each { result << { type: :error, text: "#{name}: Помилка! #{_1}" } }
      end
    end
    result
  end
end
