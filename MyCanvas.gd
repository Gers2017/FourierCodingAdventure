extends Node2D

const SAMPLES_COUNT: int = 128
const UI_PANEL_HEIGHT: float = 100.0
const CANVAS_BACKGROUND_COLOR: Color = Color.BLACK
const DFT_VECTOR_COLOR: Color = Color.FOREST_GREEN
const AVG_DFT_VECTOR_COLOR: Color = Color.YELLOW
const BORDER_COLOR: Color = Color.WEB_GRAY

@export
var wave_gradient: Gradient

@export
var freq_domain_gradient: Gradient

var amplitude: float = 100.0
var freq: float = 4.0
var freq_analysed: float = 1.0

const amplitude_max: float = 250.0
const amplitude_min: float = 60.0

@onready
var ampl_slider: HSlider = get_node("../Control/Anchor/AmplitudeG/AmplSlider")

@onready
var freq_slider: HSlider = get_node("../Control/Anchor/FreqG/FreqSlider")

@onready
var freq_value_label: Label = get_node("../Control/Anchor/FreqG/HBox/ValueLabel")

@onready
var ampl_value_label: Label = get_node("../Control/Anchor/AmplitudeG/ValueLabel")

@onready
var freq_an_slider: HSlider = get_node("../Control/Anchor/FreqAn/Slider")

@onready
var freq_an_value_label: Label = get_node("../Control/Anchor/FreqAn/ValueLabel")

func _ready():
	self.freq_slider.value = freq
	self.freq_an_slider.value = freq_analysed
	self.ampl_slider.value = amplitude
	
	self.ampl_value_label.text = str(amplitude)
	self.freq_value_label.text = str(freq)
	self.freq_an_value_label.text = str(freq_analysed)

	self.ampl_slider.max_value = self.amplitude_max
	self.ampl_slider.min_value = self.amplitude_min
	

func SignalGenerator(time: float) -> float:
	return self.amplitude * sin(TAU * self.freq * time)


func _draw():
	var _win_size_int = get_viewport().get_visible_rect().size
	var screen_size = Vector2(float(_win_size_int.x), float(_win_size_int.y))
	var windowA = WinObj.new(
		Vector2.ZERO,
		Vector2(screen_size.x, screen_size.y - UI_PANEL_HEIGHT),
		Vector2(8.0, 8.0)
	)
	
	draw_rect(windowA.make_rect(), CANVAS_BACKGROUND_COLOR, true)
	
	# Split WindowA in two sub-windows
	var windowA_hsplit = windowA.make_sub_windows(2, false, Vector2.ZERO, 12.0)
	
	# Generate Wave samples
	var wave_samples = generate_samples(SAMPLES_COUNT)

	# Draw Complex numbers in the left Sub-Window
	var windowC = windowA_hsplit[0]
	draw_rect(windowC.make_rect(), BORDER_COLOR, false, 1.0)
	draw_dt_vectors_for_freq_analyzed(windowC, wave_samples)

	# Make WindowB the right sub-window of WindowA
	var windowB = windowA_hsplit[1]
	windowB.set_padding(Vector2(4.0, 0.0))
	
	var windowB_vsplit = windowB.make_sub_windows(2, true, Vector2.ZERO, 12.0)

	for w in windowB_vsplit:
		draw_rect(w.make_rect(), BORDER_COLOR, false, 1.0)
		
	# Draw the Wave on the First Sub-Window of WindowB
	_draw_wave_in_bounds(windowB_vsplit[0])

	# Draw the Frequency Components on the Second Sub-Window of WindowB
	_draw_freq_domain(windowB_vsplit[1], wave_samples)

func generate_samples(sample_count: int = 128) -> Array[float]:
	var samples: Array[float] = []
	
	for i in range(0, sample_count):
		var t = float(i) / float(sample_count)
		var s = SignalGenerator(t)
		samples.append(s)
	
	return samples

func draw_dt_vectors_for_freq_analyzed(draw_window: WinObj, wave_samples: Array[float]) -> void:
	# Draw Complex numbers in the left Sub-Window
	var _center = draw_window.get_center()
	var points = _dft_vectors(wave_samples)
	var average_v = _compute_average_vector(points)
	const line_width = 1.0
	
	# Draw Complex numbers in screen
	for p in points:
		draw_line(_center, _center + p, DFT_VECTOR_COLOR, line_width, true)
	
	draw_line(_center, _center + average_v, AVG_DFT_VECTOR_COLOR, line_width, true)
	draw_arc(_center, 4.0, 0.0, TAU, 300, AVG_DFT_VECTOR_COLOR, 1.0, true)

func _dft_vectors(samples: Array[float]) -> Array[Vector2]:
	# An array of Complex numbers, represented as an Array of Vector2D
	var points: Array[Vector2] = []
	var N = len(samples)
	
	# Calculate the product of the Fake exponential and the signal
	for i in range(0, N):
		var t = float(i) / float(N)
		
		# Fake e^(-2pi * t * f)
		# f is the frequency to be analysed (freq_analysed)
		var zeta = -2.0 * PI * t * freq_analysed
		var fake_exp = Vector2(cos(zeta), sin(zeta))
		
		# Scale fake exponential by S(k)
		var result = fake_exp * samples[i]
		
		# Save result of fake_exp * S(k) for later
		points.append(result)
	
	return points


func _compute_average_vector(points: Array[Vector2], max_length: float = 150.0) -> Vector2:
	var avg = Vector2.ZERO
	var N = len(points)
	assert(N != 0)
	
	for p in points:
		avg += p
	
	avg = avg.normalized() * avg.length() / (2 * N)
	avg = avg.limit_length(max_length)
	return avg

func _draw_wave_in_bounds(window_draw: WinObj) -> void:
	var center = window_draw.get_center()
	var origin = window_draw.get_origin_with_padding()

	# Change origin y to be at the center y
	origin.y = center.y

	var size = window_draw.get_size_with_padding()
	
	const N = 128 # sample count
	const gap: float = 1.0 # gap between lines
	var line_width = 2.0 # individual line width

	assert((line_width + gap) * N <= size.x)
	
	var max_sample_value = size.y - 4.0
	
	for i in range(0, N):
		var t: float = i / float(N)
		# var ampl_t = (amplitude - amplitude_min) / (amplitude_max - amplitude_min)
		var ampl_t = (amplitude) / (amplitude_max) # allow from 10% to 100%
		var sample = (0.5 * SignalGenerator(t) / amplitude) * max_sample_value * ampl_t
		
		var start_point = Vector2(origin.x + i * (line_width + gap) - line_width * 0.5, origin.y)
		var end_point = start_point + Vector2.UP * sample

		if start_point.x + line_width >= (origin.x + size.x):
			break
		var _color = wave_gradient.sample(t)

		draw_line(start_point, end_point, _color, line_width)


func _draw_freq_domain(window_draw: WinObj, samples: Array[float]) -> void:
	# An array of 'Complex' numbers encoding amplitude and phase
	# Each index of the array represents the analysed frequency
	var N = len(samples)
	var fft_output = FFT.fft_setup(samples)
	var amplitude_spectrum = []
	amplitude_spectrum.resize(N)
	
	var scale_factor = 2.0 / float(N)
	for k in range(0, N):
		var L = fft_output[k].length()
		amplitude_spectrum[k] = L * scale_factor
	
	var size = window_draw.get_size_with_padding()
	var origin = window_draw.get_origin_with_padding()
	
	# Change origin.y to the bottom of the Window
	origin.y = origin.y + size.y - 10.0
	
	var line_width = 4.0
	const gap = 0.0

	assert((line_width + gap) * N <= size.x)

	# Change origin.x to be the center.x - plot_size.x / 2
	var _center = window_draw.get_center()
	var plot_size_x = (line_width + gap) * N
	origin.x = _center.x - plot_size_x / 2.0

	for i in range(0, N):
		var t = i / float(N)
		var _color = freq_domain_gradient.sample(t)
		var ampl_k = amplitude_spectrum[i]
		ampl_k = clamp(ampl_k, 0.0, size.y)
		var start_point = Vector2(origin.x + i * (line_width + gap) - line_width * 0.5, origin.y)
		var end_point = start_point + Vector2.UP * ampl_k
		draw_line(start_point, end_point, _color, line_width)

	
func _process(_delta: float) -> void:
	queue_redraw()

func _on_freq_slider_value_changed(value: float) -> void:
	self.freq = value
	assert(self.freq_value_label != null)
	self.freq_value_label.text = str(value)
	self.queue_redraw()

func _on_ampl_slider_value_changed(value: float) -> void:
	self.amplitude = value
	self.ampl_value_label.text = str(amplitude)
	self.queue_redraw()

func _on_freq_an_slider_value_changed(_new_value: float) -> void:
	self.freq_analysed = _new_value
	assert(self.freq_an_value_label != null)
	self.freq_an_value_label.text = str(_new_value)
	self.queue_redraw()
