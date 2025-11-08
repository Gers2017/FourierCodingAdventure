class_name FFT

static func _fft(samples: Array[Vector2]) -> Array[Vector2]:
	var N: int = len(samples)
	
	if N == 1:
		return samples
	
	var halfN: int = int(N / 2.0)
	var evenS: Array[Vector2] = []
	evenS.resize(halfN)
	var oddS: Array[Vector2] = []
	oddS.resize(halfN)
	
	for k in range(0, halfN):
		evenS[k] = samples[k * 2]
		oddS[k] = samples[k * 2 + 1]
	
	var evenF: Array[Vector2] = _fft(evenS)
	var oddF: Array[Vector2] = _fft(oddS)
	
	var freqbins: Array[Vector2] = []
	freqbins.resize(N)
	
	for k in range(0, halfN):
		var theta = -1.0 * TAU * k / N

		# Polar form of the complex number 'beta'
		var beta_angle = oddF[k].angle_to(Vector2.RIGHT)
		var beta_length = oddF[k].length()
		
		# Fake exponential multiplied by oddF[k]
		var cmplx: Vector2 = beta_length * Vector2(cos(theta + beta_angle), sin(theta + beta_angle))
		freqbins[k] = evenF[k] + cmplx
		freqbins[k + halfN] = evenF[k] - cmplx # important, don't delete
	
	return freqbins

static func fft_setup(samples: Array[float]):
	var samples_vec: Array[Vector2] = []
	for s in samples:
		samples_vec.append(Vector2(s, 0.0))
	
	return _fft(samples_vec)
