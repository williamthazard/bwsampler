//server setup
(Server.default = Server.local;
s.reboot;
)

//get samples
(d = Dictionary.new;
d.add(\l ->
	PathName("/mnt/chromeos/MyFiles/za").entries.collect({
		arg sf;
		Buffer.read(s, sf.fullPath);
	});
);
d.add(\m ->
	PathName("/mnt/chromeos/MyFiles/other").entries.collect({
		arg sf;
		Buffer.read(s, sf.fullPath);
	});
);
)

//set tempo
TempoClock.tempo_(180/60);

//defining our sampler
(SynthDef(\PlayBufPlayer, {
	arg out = 0,
	bufnum = 0,
	rate = 1,
	start = 0,
	end = 1,
	t_trig = 0,
	loops = 1,
	amp = 0.2,
	pan = 0,
	del1_pan = 0,
	del2_pan = 0,
	rateSlew = 0.1,
	panSlew = 1,
	bus = 0,
	delay1_time = 1,
	decay1_time = 1,
	delay1_amount = 0,
	delay2_time = 1,
	decay2_time = 1,
	delay2_amount = 0,
	reverb_amount = 0,
	room_size = 0.5,
	damp = 0.5;
	var snd,
	snd2,
	pos,
	pos2,
	frames,
	duration,
	env,
	sig,
	startA,
	endA,
	startB,
	endB,
	crossfade,
	aOrB,
	delay1,
	delay2;
	aOrB=ToggleFF.kr(t_trig);
	startA=Latch.kr(start,aOrB);
	endA=Latch.kr(end,aOrB);
	startB=Latch.kr(start,1-aOrB);
	endB=Latch.kr(end,1-aOrB);
	crossfade=Lag.ar(K2A.ar(aOrB),0.1);
	rate=Lag.kr(rate,rateSlew)*BufRateScale.kr(bufnum);
	frames=BufFrames.kr(bufnum);
	duration=frames*(end-start)/rate.abs/s.sampleRate*loops;
	env = EnvGen.ar(
		Env.new(
			levels: [0,amp,amp,0],
			times: [0,duration-0.1,0.1],
		),
		gate:t_trig,
	);
	pos = Phasor.ar(
		trig: aOrB,
		rate: rate,
		start: (((rate>0)*startA)+((rate<0)*endA))*frames,
		end: (((rate>0)*endA)+((rate<0)*startA))*frames,
		resetPos: (((rate>0)*startA)+((rate<0)*endA))*frames,
	);
	snd = BufRd.ar(
		numChannels: 1,
		bufnum: bufnum,
		phase: pos,
		interpolation: 4,
	);
	pos2 = Phasor.ar(
		trig:(1-aOrB),
		rate: rate,
		start: (((rate>0)*startB)+((rate<0)*endB))*frames,
		end: (((rate>0)*endB)+((rate<0)*startB))*frames,
		resetPos: (((rate>0)*startB)+((rate<0)*endB))*frames,
	);
	snd2=BufRd.ar(
		numChannels: 1,
		bufnum: bufnum,
		phase: pos2,
		interpolation: 4,
	);
	delay1 = CombL.ar(
		LeakDC.ar(
			(crossfade*snd)+((1-crossfade)*snd2)*env),
		2,
		delay1_time,
		decay1_time,
		delay1_amount
	);
	delay2 = CombL.ar(
		LeakDC.ar(
			(crossfade*snd)+((1-crossfade)*snd2)*env),
		2,
		delay2_time,
		decay2_time,
		delay2_amount
	);
	sig = Pan2.ar(
		FreeVerb.ar(
			MoogFF.ar(
				in: (crossfade*snd)+((1-crossfade)*snd2)*env,
				freq: \cutoff.kr(12000),
				gain: \resonance.kr(1)),
			reverb_amount,
			room_size,
			damp),
		pan
	) + Pan2.ar(
		FreeVerb.ar(
			MoogFF.ar(
				in: delay1,
				freq: \del1_cutoff.kr(12000),
				gain: \del1_resonance.kr(1)),
			reverb_amount,
			room_size,
			damp),
		del1_pan
	) + Pan2.ar(
		FreeVerb.ar(
			MoogFF.ar(
				in: delay2,
				freq: \del2_cutoff.kr(12000),
				gain: \del2_resonance.kr(1)),
			reverb_amount,
			room_size,
			damp),
		del2_pan);
	Out.ar(bus,sig)
}).play(s, [\out, 0]))

//putting three instances of our sampler in places we can refer to later
~player = Array.fill(3,{Synth(\PlayBufPlayer)});

//triggering our sampler instances
~player[0].set(\bufnum,d[\l][1],\t_trig,1,\start,0,\end,1,\loops,1,\amp,0.95,\rate,1,\bus,0)
~player[1].set(\bufnum,d[\l][18],\t_trig,1,\start,0,\end,1,\loops,1,\amp,0.95,\rate,1,\bus,0)
~player[2].set(\bufnum,d[\m][0],\t_trig,1,\start,0.01,\end,0.1,\loops,1,\amp,0.95,\rate,1,\bus,0)


//sequencing our sampler triggers
(Tdef(
	\player0, {
		var delta;
		loop {
			delta = 1.5;
			~player[0].set(\bufnum,d[\l][1],\t_trig,1,\start,0,\end,1,\amp,0.95,\rate,1,\bus,0);
			delta.yield;
		}
	}
).play(TempoClock, quant:4))

(Tdef(
	\player1, {
		var delta;
		loop {
			delta = [1,0.5].choose;
			~player[1].set(\bufnum,d[\l][18],\t_trig,1,\start,0,\end,0.5,\loops,1,\amp,0.95,\rate,1,\bus,0);
			delta.yield;
		}
	}
).play(TempoClock, quant:4))

(Tdef(
	\player2, {
		var delta;
		loop {
			delta = [3,6].choose;
			~player[2].set(\bufnum,d[\m][0],\t_trig,1,\start,rrand(0.0,1.0),\end,rrand(0.0,1.0),\loops,1,\amp,0.95,\rate,1,\bus,0);
			delta.yield;
		}
	}
).play(TempoClock, quant:4))

//stopping our trigger sequencers
Tdef(\player0).stop;
Tdef(\player1).stop;
Tdef(\player2).stop;

//setting delays
~player[2].set(\delay1_amount,0.3,\delay1_time,0.5,\decay1_time,TempoClock.beatDur*16,\del1_cutoff,800)
~player[2].set(\delay2_amount,0.3,\delay2_time,1.5,\decay2_time,TempoClock.beatDur*32,\del2_cutoff,500)

//sequencing rate changes to a sampler instance
(Tdef(
	\changer2, {
		var delta;
		loop {
			delta = [0.25,0.5,1,2,4,8].wchoose([0.05,0.05,0.2,0.2,0.25,0.25]);
			~player[2].set(\rate, [1/4,2/6,3/8,4/10,1/2,2/3,3/4,4/5,1,5/4,4/3,3/2,2/1,10/4,8/3,6/2].choose*[-1,1].choose);
			delta.yield
		}
	}
).play(TempoClock, quant: 4))

//stop sequencing rate changes
Tdef(\changer2).stop;

//creating some LFOs
(~panLFOs = Array.fill(5, {0});
~cutoffLFOs = Array.fill(5, {0});
~resonanceLFOs = Array.fill(5, {0});
5.do({
	arg i;
	~panLFOs.put(i,
		Ndef(i.asSymbol, {
			LFTri.kr(TempoClock.beatDur/rrand(1,16)).range(-1,1)
		});
	);
	~cutoffLFOs.put(i,
		Ndef((i+5).asSymbol, {
			LFTri.kr(TempoClock.beatDur/rrand(1,16)).range(300,15000)
		});
	);
	~resonanceLFOs.put(i,
		Ndef((i+10).asSymbol, {
			LFTri.kr(TempoClock.beatDur/rrand(1,16)).range(0,2)
		});
	)
}))

//modulating our samplers with our LFOs
(~player[0].set(\pan, ~panLFOs[0]);
~player[1].set(\pan, ~panLFOs[1]);
~player[2].set(\pan, ~panLFOs[2]);
~player[2].set(\del1_pan, ~panLFOs[3]);
~player[2].set(\del2_pan, ~panLFOs[4]);
~player[0].set(\cutoff, ~cutoffLFOs[0]);
~player[1].set(\cutoff, ~cutoffLFOs[1]);
~player[2].set(\cutoff, ~cutoffLFOs[2]);
~player[2].set(\del1_cutoff, ~cutoffLFOs[3]);
~player[2].set(\del2_cutoff, ~cutoffLFOs[4]);
~player[0].set(\resonance, ~resonanceLFOs[0]);
~player[1].set(\resonance, ~resonanceLFOs[1]);
~player[2].set(\resonance, ~resonanceLFOs[2]);
~player[2].set(\del1_resonance, ~resonanceLFOs[3]);
~player[2].set(\del2_resonance, ~resonanceLFOs[4]))