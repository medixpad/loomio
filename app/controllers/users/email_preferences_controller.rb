class Users::EmailPreferencesController < BaseController
  skip_before_filter :authenticate_user!
  before_filter :authenticate_user_by_unsubscribe_token_or_fallback

  def edit
    @user = user
  end

  def update
    @user = user
    if @user.update_attributes(permitted_params.user)
      flash[:notice] = "Your email settings have been updated."
      redirect_to dashboard_or_root_path
    else
      flash[:error] = "Failed to update settings"
      render :edit
    end
  end

  def mark_discussion_as_read
    @discussion = Discussion.find(params[:discussion_id])
    @event = Event.find(params[:event_id])
    DiscussionReader.for(discussion: @discussion, user: user).viewed!(@event.created_at)

    send_file Rails.root.join('app','assets','images', 'empty.gif'),
              type: 'image/gif',
              disposition: 'inline'
  end

  def mark_summary_email_as_read
    @inbox = Inbox.new(user)
    @inbox.load
    time_start = Time.at(params[:time_start].to_i).utc
    time_finish = Time.at(params[:time_finish].to_i).utc

    Queries::VisibleDiscussions.new(user: user,
                                    groups: user.inbox_groups).
                                    unread.
                                    active_since(time_start).each do |discussion|
      DiscussionReader.for(user: user, discussion: discussion).viewed!(time_finish)
      if motion = discussion.motions.voting_or_closed_after(time_start).first
        MotionReader.for(user: user, motion: motion).viewed!(time_finish)
      end
    end

    respond_to do |format|
      format.html {
        flash[:notice] = I18n.t "email.missed_yesterday.marked_as_read_success"
        redirect_to dashboard_or_root_path
      }
      format.gif {
        send_file Rails.root.join('app','assets','images', 'empty.gif'),
                  type: 'image/gif', disposition: 'inline'
      }
    end
  end

  private

  def user
    @restricted_user || current_user
  end

  def authenticate_user_by_unsubscribe_token_or_fallback
    unless (params[:unsubscribe_token].present? and @restricted_user = User.find_by_unsubscribe_token(params[:unsubscribe_token]))
      authenticate_user!
    end
  end
end
