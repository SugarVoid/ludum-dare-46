extends Node2D
class_name Meeting


signal meeting_duration_changed(new_duration)
signal meeting_finished(point_breakdowns, total_points)
signal meeting_lost()


export (String) var meeting_name = "REGIONAL SALES MEETING"
export (int) var meeting_duration = 30

export (int) var prompt_completed_points = 10
export (int) var meeting_finished_base_points = 100
export (int) var participant_left_points = -60


onready var meeting_tick_timer = $MeetingTickTimer
onready var participants = $Participants


var current_points: int = 0
var point_breakdowns: Array = []
var active_participants: int = 3

var participant_first_names = [
	"Karen",
	"Debra",
	"Bruce",
	"Peter",
	"Bill",
	"Andrew",
	"Simon",
	"Leroy",
	"Amanda",
	"Cathy",
	"Mary",
	"Lewis",
	"Kevin",
	"Angela",
	"Jim",
	"Joanna",
	"Anne",
]

var participant_last_names = [
	"McGillis",
	"Malone",
	"Scott",
	"Martin",
	"Schrute",
	"Halpert",
	"Dwyer",
	"Knope",
	"Preston",
	"Lumbergh",
	"Gibbons",
	"Bolton",
	"Banner",
	"Wayne",
	"Kitchens",
	"Perkins",
]


export (int) var difficulty_multiplier = 0 setget set_difficulty_multiplier


func set_difficulty_multiplier(multiplier):
	difficulty_multiplier = multiplier
	for participant in participants.get_children():
		participant.set_difficulty_multiplier(multiplier)

func start_meeting(meeting_name: String):
	self.meeting_name = meeting_name
	randomize()

	for participant in participants.get_children():
		participant.first_name = participant_first_names[randi() % participant_first_names.size()]
		participant.last_name = participant_last_names[randi() % participant_last_names.size()]
		participant.connect("participant_left_meeting", self, "handle_participant_left_meeting", [participant])

	meeting_tick_timer.start()


func handle_participant_left_meeting(participant: Participant):
	current_points += participant_left_points
	point_breakdowns.append({ "reason": "%s %s left the meeting" % [participant.first_name, participant.last_name], "value": participant_left_points })
	active_participants -= 1
	if active_participants == 0:
		emit_signal("meeting_lost")


func finish_meeting():
	meeting_tick_timer.stop()
	current_points += meeting_finished_base_points
	point_breakdowns.append({ "reason": "Meeting Completed", "value": meeting_finished_base_points })

	# We duplicate the breakdowns here since arrays are passed by reference, so this reference
	# will prevent this meeting from being freed. The `true` parameter is so that the array
	# is deep-copied
	var breakdown_copy = point_breakdowns.duplicate(true)
	emit_signal("meeting_finished", breakdown_copy, current_points)


func get_meeting_participants() -> Array:
	return participants.get_children()


func _on_MeetingTickTimer_timeout() -> void:
	for participant in participants.get_children():
		participant.engagement_level -= 0.5 * difficulty_multiplier

	meeting_duration -= 1
	emit_signal("meeting_duration_changed", meeting_duration)
	if meeting_duration == 0:
		finish_meeting()


func get_oldest_prompt() -> Prompt:
	var oldest_with_question = null
	for participant in participants.get_children():
		if participant.current_question_time > 0:
			if oldest_with_question != null:
				if oldest_with_question.current_question_time > participant.current_question_time:
					oldest_with_question = participant
			else:
				oldest_with_question = participant
	if oldest_with_question:
		var prompt = ParticipantPrompt.new()
		prompt.prompt = oldest_with_question.current_question.prompt
		prompt.response = oldest_with_question.current_question.response
		prompt.participant_last_name = oldest_with_question.last_name
		return prompt
	return null


func handle_prompt_completed(prompt: ParticipantPrompt, success: bool) -> void:
	print("Handling completed prompt")
	current_points += prompt_completed_points
	for participant in participants.get_children():
		if participant.last_name == prompt.participant_last_name:
			point_breakdowns.append({ "reason": "Question answered for %s" % participant.first_name, "value": prompt_completed_points})
			participant.engagement_level += 20
			participant.clear_question()
