class EventsController < ApplicationController
  #before_filter :authenticate_user!
  before_action :set_event, only: [:show, :edit, :update, :destroy, :accept_request, :reject_request]
  before_action :event_owner!, only: [:edit, :update, :destroy, :accept, :reject]
  before_filter :authenticate_user!, only: [:new, :edit, :create, :update, :destroy]
  
  respond_to :html, :json

  def index
    if params[:tag]
      @events = Event.tagged_with(params[:tag])
    else
      @events = Event.all
    end
    #respond_with(@events)
  end

  def show
    @event_owner = @event.event_owner(@event.organizer_id)
    @attendees = Event.show_accepted_attendees(@event.id)
    @pending_requests = Event.pending_requests(@event.id)
    respond_with(@event)
  end

  def new
    @event = Event.new
    respond_with(@event)
  end

  def edit
  end

  def join
    @attendance = Attendance.join_event(current_user.id, params[:event_id], 'request_sent')
    @attendance.save
    #respond_with @attendance

     respond_to do |format|
       format.html { redirect_to(events_path, :notice => 'Request Sent') }
     end
  end

  def create
    @event = current_user.organized_events.new(event_params)
    respond_to do |format|

      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.'}
        format.json { render action: 'show', status: :created, location: @event}
      else
        format.html { render action: 'new'}
        format.json { render json: @event.errors, status: :unprocessable_entity}
      end
    end
  end

  def update
    @event.update(event_params)
    respond_with(@event)
  end

  def destroy
    @event.destroy
    respond_with(@event)
  end

  def accept_request
    @event = Event.find(params[:event_id])
    @attendance = Attendance.find_by(id: params[:attendance_id]) rescue nil
    
    #'Application Accepted' if @attendance.save
    @attendance.accept!

    redirect_to(@event)
  end

  def reject_request
    @event = Event.find(params[:event_id])
    @attendance = Attendance.find_by(id: params[:attendance_id]) rescue nil
    @attendance.reject!
    #'Application Rejected' if @attendance.save
    redirect_to(@event)

     
     #format.html { redirect_to @event, notice: 'Rejected.'}
  end

  def my_events
    @events = current_user.organized_events
  end

  private
    def set_event
      #@event = Event.find(params[:id])
      if params[:event_id].present?
        @event = Event.friendly.find(params[:event_id])
      else
        @event =Event.friendly.find(params[:id])
      end
    end

    def event_params
      params.require(:event).permit(:title, :start_date, :end_date, :location, :agenda, :address, :organizer_id, :all_tags, :user_id)
    end

    def event_owner!
      authenticate_user!
      if @event.organizer_id != current_user.id
        redirect_to events_path
        flash[:notice] = 'You do not have enough permissions to do this'
      end
    end


end
