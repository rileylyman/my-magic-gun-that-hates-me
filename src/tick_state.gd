class_name TickState
extends Object

var cards: Array[Card] = []
var hand: Array[Card] = []

var today_fired_cards: Array[Card] = []
var previous_day_fired_cards: Array[Card] = []
var current_card: Card

var score: int = 0
var should_fire: bool = false
var bonus_score: int = 0
var days: int = 0
var max_days: int = 0
var gm: GameManager
