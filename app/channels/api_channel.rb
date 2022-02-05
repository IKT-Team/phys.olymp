class ApiChannel < ApplicationCable::Channel
  rescue_from(ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound) { dispatch_self 'errors/push', _1 }

  def subscribed
    ensure_confirmation_sent
    dispatch_self 'app/start'
    dispatch_self 'users/load', User.joins(contest: :tasks).where(tasks: { id: task_id }).order(:secret).pluck(:secret)
    dispatch_self 'criteria/load', task_criterions.order(:position)
    dispatch_self 'results/load', CriterionUserResult.includes(:user).where(criterion: task_criterions)
    dispatch_self 'app/ready'
    stream_from task_id
  end

  def add_criterion
    criterion = task_criterions.create! position: task_criterions.count
    dispatch_all 'criteria/add', criterion
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def update_criterion data
    criterion = task_criterions.find data['id']
    criterion.update! data['params']
    dispatch_all 'criteria/cleanUpdate', id: criterion.id, token: data['token'], value: criterion
  end

  def delete_criterion data
    criterion = task_criterions.find data['id']
    criterion.destroy!
    task_criterions.where('position > ?', criterion.position).update_all('position = position - 1')
    dispatch_all 'criteria/delete', data['id']
  end

  def drag_drop data
    from, to = data.values_at 'from', 'to'
    if from > to
      task_criterions.where('position BETWEEN ? AND ?', to, from)
        .update_all(['position = (CASE WHEN position = ? THEN ? ELSE position + 1 END)', from, to])
    else
      task_criterions.where('position BETWEEN ? AND ?', from, to)
        .update_all(['position = (CASE WHEN position = ? THEN ? ELSE position - 1 END)', from, to])
    end
  ensure
    dispatch_all 'criteria/loadPosition', task_criterions.order(:position).pluck(:id, :position).to_h
  end

  def write_result data
    performed = RedisLockManager.with_lock lock_key(data), client_id do
      user = User.find_by! secret: data['user']
      criterion = task_criterions.find data['criterion']
      result = CriterionUserResult.create_or_find_by!(user:, criterion:)
      result.update! value: data['value']
      dispatch_all 'results/cleanUpdate', result.as_json.merge(token: data['token'])
    end
    dispatch_self 'errors/push', "Write failed: Lock #{lock_key data} was acquired by someone else" unless performed
  end

  def acquire_lock data
    if RedisLockManager.acquire lock_key(data), client_id
      dispatch_all 'locks/acquire', data.merge(client_id:)
    else
      dispatch_self 'errors/push', "Lock #{lock_key data} was acquired by someone else"
    end
  end

  def release_lock data
    if RedisLockManager.release lock_key(data), client_id
      dispatch_all 'locks/release', data.merge(client_id:)
    else
      dispatch_self 'errors/push', "Lock #{lock_key data} was acquired by someone else"
    end
  end

  private

  def dispatch_self action, payload = nil
    transmit({ type: action, payload: })
  end

  def dispatch_all action, payload = nil
    ActionCable.server.broadcast task_id, { type: action, payload: }
  end

  def task_criterions
    Criterion.where task_id:
  end

  def lock_key(data) = data.values_at('user', 'criterion').join(':')
end
