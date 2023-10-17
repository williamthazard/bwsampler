(
//server
Server.default = Server.local;
o = Server.default.options;
/*o.inDevice_("Scarlett 4i4 USB");
o.outDevice_("External Headphones");*/
s.latency_(0.2);
//ServerOptions.devices;

//tempo
~timer = LinkClock.new(2).latency_(Server.default.latency).quantum_(0);

//buffer allocation
~delBuf = Buffer.alloc(s, s.sampleRate * (~timer.beatDur*512), 1);
~micBus = Bus.audio(s, 1);
~ptrBus = Bus.audio(s, 1);

//identify where we'll be pulling our samples from
~sampleSpot = "/mnt/chromeos/MyFiles/other";
//w.view.children.size.do({arg i; i.post; " | ".post; w.view.children[i].postln})

//wait
s.waitForBoot({

	//get samples
	d = Dictionary.new;
	d.add(\p ->
		PathName(~sampleSpot).entries.collect({
			arg sf;
			Buffer.read(s, sf.fullPath);
		});
	);

	~samples = Array.fill(
			PathName(~sampleSpot).files.size,
		{
			arg i;
			PathName(~sampleSpot).files[i].fullPath
		}
	);
	~samp = Array.fill(
		3,
		{
			arg i;
			i
		}
	);
	~startTime = Array.fill(
		3,
		{
			arg i;
			i
		}
	);
	~endTime = Array.fill(
		3,
		{
			arg i;
			i
		}
	);
	~startSec = Array.fill(
		3,
		{
			arg i;
			i
		}
	);
	~endSec = Array.fill(
		3,
		{
			arg i;
			i
		}
	);
	~currentRate = Array.fill(
		3,
		{
			1
		}
	);
	~rateRand = Array.fill(
		3,
		{
			0
		}
	);
	~randRate = Array.fill(
		3,
		{
			1
		}
	);
	~selectRand = Array.fill(
		3,
		{
			0
		}
	);
	~randStart = Array.fill(
		3,
		{
			0
		}
	);
	~randEnd = Array.fill(
		3,
		{
			1
		}
	);
	~duration = Array.fill(
		3,
		{
			1
		}
	);
	Window.closeAll;
	w = Window("Bridge Way Instrument", Rect(
		Window.availableBounds.width/2,
		150,
		(Window.availableBounds.width/2),
		(Window.availableBounds.width/2)-40),
	border:true)
	.front
	.background_(
		Color.black
	).alwaysOnTop_(
		true
	).alpha_(
		0.75
	).onClose_(
		{
			~bf.free;
			~fb.free
		}
	);

	w.view.decorator_(
		FlowLayout(
			w.bounds,
			5@5,
			0@0
		)
	);

	k = Window("lissajous scope", Rect(
		Window.availableBounds.width/4,
		150,
		(Window.availableBounds.width/4),
		(Window.availableBounds.width/4)-40),
	border:true)
	.front
	.background_(
		Color.black
	).alwaysOnTop_(
		true
	).alpha_(
		0.75
	).onClose_(
		{
			~li.stop;
		}
	);

	z = Window("overlay scope", Rect(
		Window.availableBounds.width/4,
		190+k.bounds.height,
		(Window.availableBounds.width/4),
		(Window.availableBounds.width/4)-40),
	border:true)
	.front
	.background_(
		Color.black
	).alwaysOnTop_(
		true
	).alpha_(
		0.75
	).onClose_(
		{
			~ov.stop;
		}
	);

	~comps = Array.fill(14,{0});

	Array.fill(3,
		{
			arg i;
			Button(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.height/8.1
				)
			).states_(
				[
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.25
						),
						Color.new(
							1,
							1,
							1,
							0.25
						)
					],
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.75
						),
						Color.new(
							1,
							1,
							1,
							0.75
						)
					]
				]
			).mouseDownAction_(
				{
					arg view;
					if(
						view.value == 3,
						{
							view.value = 1;
						},
						{
							Tdef(i.asSymbol).play;
							("playing sampler " ++ (i+1)).postln
						}
					);
					if(
						view.value == 1,
						{
							view.value == 0;
							Tdef(i.asSymbol).stop;
							("stopping sampler " ++ (i+1)).postln
						}
					)
				}
			);
			~comps[i] = CompositeView(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.width/8.1
				)
			);
			~comps[i].decorator = FlowLayout(~comps[i].bounds);
			Array.fill(4,
				{
					arg j;
					Knob(
						~comps[i],
						(
							~comps[i].bounds.width/2.4
						)@(
							~comps[i].bounds.width/2.3
						)
					).color_(
						[
							Color.new(
								1,
								1,
								1,
								0.5
							),
							Color.new(
								1,
								1,
								1,
								0.5
							),
							Color.new(
								0,
								0,
								0,
								0.5
							),
							Color.new(
								0,
								0,
								0,
								0.5
							)
						]
					).action_(
						{
							arg obj;
							if(
								j == 0,
								{
									t[i].set(\amp,obj.value)
								}
							);
							if(
								j == 1,
								{
									t[i].set(\rate,~orderedRates[obj.value.linlin(0,1,0,~orderedRates.size-1).round]);
									~currentRate[i] = ~orderedRates[obj.value.linlin(0,1,0,~orderedRates.size-1).round]
								}
							);
							if(
								j == 2,
								{

									t[i].set(\room_size,obj.value)
								}
							);
							if(
								j == 3,
								{

									t[i].set(\damp,obj.value)
								}
							);
						}
					).value_(
						if(
							j == 1,
							{
								0.7
							},
							{
								0.5
							}
						)
					)
				}
			);
		}
	);
	~comps[3] = CompositeView(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.width/8.1
				)
			);
	~comps[3].decorator = FlowLayout(~comps[3].bounds);
	Button(
		~comps[3],
		(
			~comps[3].bounds.width-15
		)@(
			(~comps[3].bounds.height/2)-10
		)
	).states_(
		[
			[ " ",
				Color.new(
					1,
					1,
					1,
					0.25
				),
				Color.new(
					1,
					1,
					1,
					0.25
				)
			],
			[ " ",
				Color.new(
					1,
					1,
					1,
					0.75
				),
				Color.new(
					1,
					1,
					1,
					0.75
				)
			]
		]
	).mouseDownAction_(
		{
			arg view;
			if(
				view.value == 3,
				{
					view.value = 1
				}
			);
			if(
				view.value == 0,
				{
					2.do(
						{
							arg i;
							~inMic[i].set(\amp,~comps[4].children[0].value)
						}
					);
					"mic on".postln;
				},
				{
					2.do(
						{
							arg i;
							~inMic[i].set(\amp,0);
						}
					);
					"mic off".postln;
				}
			)
		}
	);
	2.do(
		{
			arg i;
			Button(
				~comps[3],
				(
					(~comps[3].bounds.width/2)-10
				)@(
					(~comps[3].bounds.height/2)-5
				)
			).states_(
				[
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.25
						),
						Color.new(
							1,
							1,
							1,
							0.25
						)
					],
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.75
						),
						Color.new(
							1,
							1,
							1,
							0.75
						)
					]
				]
			).mouseDownAction_(
				{
					arg view;
					if(
						view.value == 3,
						{
							view.value = 1
						}
					);
					if(
						i == 0,
						{
							if(
								view.value == 0,
								{
									~delMic.set(\amp, ~comps[4].children[1].value);
									"recording to Carter's Delay".postln;
								},
								{
									~delMic.set(\amp, 0);
									"stopped recording to Carter's Delay".postln;
								}
							)
						},
						{
							if(
								view.value == 0,
								{
									7.do({
										arg i;
										~g[i].set(\amp, ~comps[4].children[2].value)
									});
									8.do({
										arg i;
										~g[i+7].set(\amp, ~comps[4].children[3].value)
									});
									"Carter's Delay activated".postln;
								},
								{
									15.do({
										arg i;
										~g[i].set(\amp, 0)
									});
									"Carter's Delay deactivated".postln;
								}
							)
						}
					)
				}
			)
		}
	);
	~comps[4] = CompositeView(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.width/8.1
				)
			);
	~comps[4].decorator = FlowLayout(~comps[4].bounds);
	4.do(
		{
			arg i;
			Knob(
				~comps[4],
				(
					~comps[4].bounds.width/2.4
				)@(
					~comps[4].bounds.width/2.3
				)
			).color_(
				[
					Color.new(
						1,
						1,
						1,
						0.5
					),
					Color.new(
						1,
						1,
						1,
						0.5
					),
					Color.new(
						0,
						0,
						0,
						0.5
					),
					Color.new(
						0,
						0,
						0,
						0.5
					)
				]
			).action_(
				{
					arg obj;
					if(
						i == 0,
						{
							2.do(
								{
									arg j;
									if(
										~comps[3].children[0].value == 1,
										{
											~inMic[j].set(\amp,obj.value)
										}
									)
								}
							)
						}
					);
					if(
						i == 1,
						{
							if(
								~comps[3].children[1].value == 1,
								{
									~delMic.set(\amp,obj.value)
								}
							)
						}
					);
					if(
						i == 2,
						{
							7.do(
								{
									arg j;
									if(
										~comps[3].children[2].value == 1,
										{
											~g[j].set(\amp,obj.value)
										}
									)
								}
							)
						}
					);
					if(
						i == 3,
						{
							8.do(
								{
									arg j;
									if(
										~comps[3].children[2].value == 1,
										{
											~g[j+7].set(\amp,obj.value)
										}
									)
								}
							)
						}
					)
				}
			).value_(
				0.7
			)
		}
	);
	3.do(
		{
			arg n;
			SoundFileView(
				w,
				(
					w.bounds.width
				)@(
					w.bounds.height/8.1
				)
			).peakColor_(
				Color.new(
					1,
					1,
					1,
					0.5
				)
			).rmsColor_(
				Color.new(
					1,
					1,
					1,
					0.5
				)
			).waveColors_(
				[
					Color.new(
						1,
						1,
						1,
						0.5
					)
				],
				[
					Color.new(
						1,
						1,
						1,
						0.5
					)
				]
			).gridResolution_(
				~timer.beatDur
			).gridColor_(
				Color.new(
					1,
					1,
					1,
					0.25
				)
			).timeCursorOn_(
				true
			).timeCursorColor_(
				Color.new(
					1,
					1,
					1,
					0.5
				)
			).action_(
				{
					~startTime[n] = w.view.children[8+(n*10)].selections[0][0].linlin(
						0,
						d[\p][w.view.children[(8+(n*10))+1].value].numFrames,
						0,
						1
					);
					~startSec[n] = w.view.children[8+(n*10)].selections[0][0]/s.sampleRate;
					if(
						w.view.children[8+(n*10)].selections[0][1] == 0,
						{
							if(
								(~startTime[n] + (~timer.beatDur*0.125)) < 1,
								{
									~endTime[n] = ~startTime[n] + (~timer.beatDur*0.125)
								},
								{
									~endTime[n] = 1
								}
							);
							~endSec[n] = ~startSec[n] + (~timer.beatDur*0.125);
						},
						{
							~endTime[n] = w.view.children[8+(n*10)].selections[0][1].linlin(
								0,
								d[\p][w.view.children[(8+(n*10))+1].value].numFrames,
								0,
								1
							);
							~endSec[n] = w.view.children[8+(n*10)].selections[0][1]/s.sampleRate;
						}
					)
				}
			).load(
				~samples[0]
			);
			PopUpMenu(
				w,
				(
					w.bounds.width/8.1
				)@(
					20
				)
			).items_(
				~samples.size.collect(
					{
						arg i;
						PathName(~samples[i]).fileNameWithoutExtension
					}
				)
			).background_(
				Color.new(
					0,
					0,
					0,
					0.5
				)
			).stringColor_(
				Color.new(
					1,
					1,
					1,
					0.5
				)
			).action_(
				{
					arg obj;
					w.view.children[8+(n*10)].load(~samples[obj.value]);
					~samp[n] = obj.value
				}
			);
			6.do(
				{
					arg i;
					Button(
						w,
						(
							w.bounds.width/8.1
						)@(
							20
						)
					).states_(
						[
							[ " ",
								Color.new(
									1,
									1,
									1,
									0.25
								),
								Color.new(
									1,
									1,
									1,
									0.25
								)
							],
							[ " ",
								Color.new(
									1,
									1,
									1,
									0.75
								),
								Color.new(
									1,
									1,
									1,
									0.75
								)
							]
						]
					).mouseDownAction_(
						{
							arg view;
							if(
								view.value == 3,
								{
									view.value = 1
								}
							);
							if(
								i == 0,
								{
									if(
										view.value == 0,
										{
											t[n].set(\reverb_amount, 0.5);
											("sampler " ++ (n+1) ++ " reverb on").postln;
										},
										{
											t[n].set(\reverb_amount, 0);
											("sampler " ++ (n+1) ++ " reverb off").postln;
										}
									)
								}
							);
							if(
								i == 1,
								{
									if(
										view.value == 0,
										{
											t[n].set(\pan, Ndef(rrand(0,15).asSymbol));
											("sampler " ++ (n+1) ++ " pan LFO on").postln;
										},
										{
											t[n].set(\pan, 0);
											("sampler " ++ (n+1) ++ " pan LFO off").postln;
										}
									)
								}
							);
							if(
								i == 2,
								{
									if(
										view.value == 0,
										{
											t[n].set(\cutoff, Ndef((n+16).asSymbol));
											("sampler " ++ (n+1) ++ " cutoff LFO on").postln;
										},
										{
											t[n].set(\cutoff, 15000);
											("sampler " ++ (n+1) ++ " cutoff LFO off").postln;
										}
									)
								}
							);
							if(
								i == 3,
								{
									if(
										view.value == 0,
										{
											t[n].set(\resonance, Ndef((n+32).asSymbol));
											("sampler " ++ (n+1) ++ " resonance LFO on").postln;
										},
										{
											t[n].set(\resonance, 1);
											("sampler " ++ (n+1) ++ " resonance LFO off").postln;
										}
									)
								}
							);
							if(
								i == 4,
								{
									if(
										view.value == 0,
										{
											~rateRand[n] = 1;
											("sampler " ++ (n+1) ++ " rate randomizer on").postln;
										},
										{
											~rateRand[n] = 0;
											("sampler " ++ (n+1) ++ " rate randomizer off").postln;
										}
									)
								}
							);
							if(
								i == 5,
								{
									if(
										view.value == 0,
										{
											~selectRand[n] = 1;
											("sampler " ++ (n+1) ++ " selection randomizer on").postln;
										},
										{
											~selectRand[n] = 0;
											("sampler " ++ (n+1) ++ " selection randomizer off").postln;
										}
									)
								}
							)
						}
					)
				}
			);
			2.do(
				{
					arg i;
					Button(
						w,
						(
							w.bounds.width/16.5
						)@(
							20
						)
					).states_(
						[
							[ " ",
								Color.new(
									1,
									1,
									1,
									0.25
								),
								Color.new(
									1,
									1,
									1,
									0.25
								)
							],
							[ " ",
								Color.new(
									1,
									1,
									1,
									0.75
								),
								Color.new(
									1,
									1,
									1,
									0.75
								)
							]
						]
					).mouseDownAction_(
						{
							arg view;
							if(
								view.value == 3,
								{
									view.value = 1;
								},
								{
									if(
										i == 0,
										{
											t[n].set(\delay1_pan, Ndef(rrand(0,16).asSymbol));
											("sampler " ++ (n+1) ++ " delay 1 pan LFO activated").postln
										},
										{
											t[n].set(\delay2_pan, Ndef(rrand(0,16).asSymbol));
											("sampler " ++ (n+1) ++ " delay 2 pan LFO activated").postln
										}
									)
								}
							);
							if(
								view.value == 1,
								{
									view.value == 0;
									if(
										i == 0,
										{
											t[n].set(\delay1_pan, ~comps[n+6].children[3].value.linlin(0,1,-1,1));
											("sampler " ++ (n+1) ++ " delay 1 pan LFO deactivated").postln
										},
										{
											t[n].set(\delay2_pan, ~comps[n+11].children[3].value.linlin(0,1,-1,1));
											("sampler " ++ (n+1) ++ " delay 2 pan LFO deactivated").postln
										}
									)
								}
							)
						}
					)
				}
			)
		}
	);
	Array.fill(3,
		{
			arg i;
			Button(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.height/8.1
				)
			).states_(
				[
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.25
						),
						Color.new(
							1,
							1,
							1,
							0.25
						)
					],
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.75
						),
						Color.new(
							1,
							1,
							1,
							0.75
						)
					]
				]
			).mouseDownAction_(
				{
					arg view;
					if(
						view.value == 3,
						{
							view.value = 1;
						},
						{
							t[i].set(\delay1_amount, ~comps[i+6].children[0].value);
							("sampler " ++ (i+1) ++ " delay 1 activated").postln
						}
					);
					if(
						view.value == 1,
						{
							view.value == 0;
							t[i].set(\delay1_amount, 0);
							("sampler " ++ (i+1) ++ " delay 1 deactivated").postln
						}
					)
				}
			);
			~comps[i+6] = CompositeView(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.width/8.1
				)
			);
			~comps[i+6].decorator = FlowLayout(~comps[i+6].bounds);
			Array.fill(4,
				{
					arg j;
					Knob(
						~comps[i+6],
						(
							~comps[i+6].bounds.width/2.4
						)@(
							~comps[i+6].bounds.width/2.3
						)
					).color_(
						[
							Color.new(
								1,
								1,
								1,
								0.5
							),
							Color.new(
								1,
								1,
								1,
								0.5
							),
							Color.new(
								0,
								0,
								0,
								0.5
							),
							Color.new(
								0,
								0,
								0,
								0.5
							)
						]
					).action_(
						{
							arg obj;
							if(
								j == 0,
								{
									if(
										w.view.children[38+(2*i)].value == 1,
										{
											t[i].set(\delay1_amount,obj.value)
										}
									)
								}
							);
							if(
								j == 1,
								{
									t[i].set(\delay1_time,obj.value.linlin(0,1,0.1,2));
								}
							);
							if(
								j == 2,
								{
									t[i].set(\decay1_time,obj.value.linlin(0,1,0.1,60))
								}
							);
							if(
								j == 3,
								{
									t[i].set(\del1_pan,obj.value.linlin(0,1,-1,1))
								}
							);
						}
					).value_(
						0.5
					)
				}
			);
		}
	);
	~comps[9] = CompositeView(
		w,
		(
			w.bounds.width/4.05
		)@(
			w.bounds.width/8.2
		)
	);
	~comps[9].decorator = FlowLayout(~comps[9].bounds);
	6.do(
		{
			arg i;
			Button(
				~comps[9],
				(
					~comps[9].bounds.width/3.3
				)@(
					~comps[9].bounds.height/2.3
				)
			).states_(
				[
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.25
						),
						Color.new(
							1,
							1,
							1,
							0.25
						)
					],
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.75
						),
						Color.new(
							1,
							1,
							1,
							0.75
						)
					]
				]
			).mouseDownAction_(
				{
					arg view;
					if(
						view.value == 3,
						{
							view.value = 1;
						},
						{
							if(
								i < 3,
								{
									t[i].set(\del1_cutoff, Ndef(rrand(16,31).asSymbol));
									("sampler " ++ (i+1) ++ " delay 1 cutoff LFO activated").postln
								},
								{
									t[i-3].set(\del1_resonance, Ndef(rrand(32,47).asSymbol));
									("sampler " ++ (i-2) ++ " delay 1 resonance LFO activated").postln
								}
							)
						}
					);
					if(
						view.value == 1,
						{
							view.value == 0;
							if(
								i < 3,
								{
									t[i].set(\del1_cutoff, w.view.children[i+55].x);
									("sampler " ++ (i+1) ++ " delay 1 cutoff LFO deactivated").postln
								},
								{
									t[i-3].set(\del1_resonance, w.view.children[i+52].y);
									("sampler " ++ (i-2) ++ " delay 1 resonance LFO deactivated").postln
								}
							)
						}
					)
				}
			);
		}
	);
	Array.fill(3,
		{
			arg i;
			Button(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.height/8.1
				)
			).states_(
				[
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.25
						),
						Color.new(
							1,
							1,
							1,
							0.25
						)
					],
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.75
						),
						Color.new(
							1,
							1,
							1,
							0.75
						)
					]
				]
			).mouseDownAction_(
				{
					arg view;
					if(
						view.value == 3,
						{
							view.value = 1;
						},
						{
							t[i].set(\delay2_amount, ~comps[i+11].children[0].value);
							("sampler " ++ (i+1) ++ " delay 2 activated").postln
						}
					);
					if(
						view.value == 1,
						{
							view.value == 0;
							t[i].set(\delay2_amount, 0);
							("sampler " ++ (i+1) ++ " delay 2 deactivated").postln
						}
					)
				}
			);
			~comps[i+11] = CompositeView(
				w,
				(
					w.bounds.width/8.1
				)@(
					w.bounds.width/8.1
				)
			);
			~comps[i+11].decorator = FlowLayout(~comps[i+11].bounds);
			Array.fill(4,
				{
					arg j;
					Knob(
						~comps[i+11],
						(
							~comps[i+11].bounds.width/2.4
						)@(
							~comps[i+11].bounds.width/2.3
						)
					).color_(
						[
							Color.new(
								1,
								1,
								1,
								0.5
							),
							Color.new(
								1,
								1,
								1,
								0.5
							),
							Color.new(
								0,
								0,
								0,
								0.5
							),
							Color.new(
								0,
								0,
								0,
								0.5
							)
						]
					).action_(
						{
							arg obj;
							if(
								j == 0,
								{
									if(
										w.view.children[45+(2*i)].value == 1,
										{
											t[i].set(\delay2_amount,obj.value)
										}
									)
								}
							);
							if(
								j == 1,
								{
									t[i].set(\delay2_time,obj.value.linlin(0,1,0.1,2));
								}
							);
							if(
								j == 2,
								{
									t[i].set(\decay2_time,obj.value.linlin(0,1,0.1,60))
								}
							);
							if(
								j == 3,
								{
									t[i].set(\del2_pan,obj.value.linlin(0,1,-1,1))
								}
							);
						}
					).value_(
						0.5
					)
				}
			);
		}
	);
	~comps[10] = CompositeView(
		w,
		(
			w.bounds.width/4.05
		)@(
			w.bounds.width/8.2
		)
	);
	~comps[10].decorator = FlowLayout(~comps[10].bounds);
	6.do(
		{
			arg i;
			Button(
				~comps[10],
				(
					~comps[10].bounds.width/3.3
				)@(
					~comps[10].bounds.height/2.3
				)
			).states_(
				[
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.25
						),
						Color.new(
							1,
							1,
							1,
							0.25
						)
					],
					[ " ",
						Color.new(
							1,
							1,
							1,
							0.75
						),
						Color.new(
							1,
							1,
							1,
							0.75
						)
					]
				]
			).mouseDownAction_(
				{
					arg view;
					if(
						view.value == 3,
						{
							view.value = 1;
						},
						{
							if(
								i < 3,
								{
									t[i].set(\del2_cutoff, Ndef(rrand(16,31).asSymbol));
									("sampler " ++ (i+1) ++ " delay 2 cutoff LFO activated").postln
								},
								{
									t[i-3].set(\del2_resonance, Ndef(rrand(32,47).asSymbol));
									("sampler " ++ (i-2) ++ " delay 2 resonance LFO activated").postln
								}
							)
						}
					);
					if(
						view.value == 1,
						{
							view.value == 0;
							if(
								i < 3,
								{
									t[i].set(\del2_cutoff, w.view.children[i+55].x);
									("sampler " ++ (i+1) ++ " delay 2 cutoff LFO deactivated").postln
								},
								{
									t[i-3].set(\del2_resonance, w.view.children[i+52].y);
									("sampler " ++ (i-2) ++ " delay 2 resonance LFO deactivated").postln
								}
							)
						}
					)
				}
			);
		}
	);
	3.do(
		{
			arg i;
			3.do(
				{
					arg j;
					Slider2D(
						w,
						(
							w.view.bounds.width/3.05
						)@(
							w.view.bounds.width/24.1+4
						)
					).action_(
						{
							arg obj;
							if(
								i == 0,
								{
									t[j].set(\cutoff, obj.x.linexp(0,1,300,15000), \resonance, obj.y.linlin(0,1,0,3))
								}
							);
							if(
								i == 1,
								{
									t[j].set(\del1_cutoff, obj.x.linexp(0,1,300,15000), \del1_resonance, obj.y.linlin(0,1,0,3))
								}
							);
							if(
								i == 2,
								{
									t[j].set(\del2_cutoff, obj.x.linexp(0,1,300,15000), \del2_resonance, obj.y.linlin(0,1,0,3))
								}
							);
						}
					)
				}
			)
		}
	);
	~color_vals = Array.fill(3,{Array.fill(4,{127})});
	~bf = Buffer.alloc(Server.default,4096,2);
	~fb = Bus.audio(Server.default,2);

	~li = ScopeView(k,
		Rect(0,
			0,
			k.view.bounds.width,
			k.view.bounds.height))
	.bufnum_(~bf.bufnum)
	.server_(Server.default)
	.style_(2)
	.xZoom_(20)
	.yZoom_(20)
	.waveColors_(
		[
			Color.new255(
				~color_vals[0][0],
				~color_vals[1][0],
				~color_vals[2][0]
			),
			Color.new255(
				~color_vals[0][1],
				~color_vals[1][1],
				~color_vals[2][1]
			)
		]
	)
	.background_(Color.black)
	.start;

	~ov = ScopeView(z,
		Rect(0,
			0,
			z.view.bounds.width,
			z.view.bounds.height))
	.bufnum_(~bf.bufnum)
	.server_(Server.default)
	.style_(1)
	.xZoom_(10)
	.yZoom_(10)
	.waveColors_(
		[
			Color.new255(
				~color_vals[0][0],
				~color_vals[1][0],
				~color_vals[2][0]
			),
			Color.new255(
				~color_vals[0][1],
				~color_vals[1][1],
				~color_vals[2][1]
			)
		]
	)
	.background_(Color.black)
	.start;

	Task(
		{
			var delta = ~timer.beatDur/2;
			loop {
				3.do({
					arg i;
					4.do({
						arg j;
						if(
							~color_vals[i][j] == 255,
							{
								~color_vals[i][j] = ~color_vals[i][j]-[0,1].choose
							}
						);
						if(
							~color_vals[i][j] == 0,
							{
								~color_vals[i][j] = ~color_vals[i][j]+[0,1].choose
							}
						);
						if(
							(~color_vals[i][j] < 255) && (~color_vals[i][j] > 0),
							{
								~color_vals[i][j] = ~color_vals[i][j]+[0,1,-1].wchoose([0.5,0.25,0.25])
							}
						);
					});
				});
				~li.waveColors_(
					[
						Color.new255(
							~color_vals[0][0],
							~color_vals[1][0],
							~color_vals[2][0]
						),
						Color.new255(
							~color_vals[0][1],
							~color_vals[1][1],
							~color_vals[2][1]
						)
					]
				);
				~ov.waveColors_(
					[
						Color.new255(
							~color_vals[0][2],
							~color_vals[1][2],
							~color_vals[2][2]
						),
						Color.new255(
							~color_vals[0][3],
							~color_vals[1][3],
							~color_vals[2][3]
						)
					]
				);
				3.do(
					{
						arg i;
						if(
							~rateRand[i] == 1,
							{
								~comps[i].children[1].value_(~currentRate[i].linlin(-2,2,0,1));
							}
						)
					}
				);
				delta.yield;
			}
		},AppClock
	).play;
	3.do(
		{
			arg i;
			Task(
				{
					var delta;
					delta = ~duration[i]*~timer.beatDur;
					loop{
						if(
							~selectRand[i] == 1,
							{
								w.view.children[8+(i*10)].setSelection(
									0,
									[
										~randStart[i].linlin(
											0,
											1,
											0,
											d[\p][w.view.children[(8+(i*10))+1].value].numFrames
										),
										~randEnd[i].linlin(
											0,
											1,
											0,
											d[\p][w.view.children[(8+(i*10))+1].value].numFrames-~randStart[i].linlin(0,1,0,d[\p][w.view.children[(8+(i*10))+1].value].numFrames)
										)
									]
								);
								w.view.children[8+(i*10)].timeCursorPosition_(~randStart[i].linlin(0,1,0,d[\p][w.view.children[(8+(i*10))+1].value].numFrames))
							}
						);
						delta.yield;
					}
				},AppClock
			).play
		}
	);
	(
		// listening to the bus, using ScopeOut2 to write it to the buffer
		~af = SynthDef("duoscope", { arg bus, bufnum;
			var z;
			z = In.ar(bus, 2);
			ScopeOut2.ar(z, bufnum);
			Out.ar(0, z);
		}).play(
			target: RootNode(Server.default),
			args: [\bus, ~fb.index, \bufnum, ~bf.bufnum],
			addAction: \addToTail // make sure it goes after what you are scoping
		);
	);

	//mic
	SynthDef.new(\mic, {
		arg in=0,
		out=0,
		amp=1;
		var sig;
		sig=SoundIn.ar(in)*amp;
		Out.ar(out,sig);
	}).add;

	//delay
	SynthDef(\ptr, {
		arg out=0,
		buf=0,
		rate=1;
		var sig;
		sig=Phasor.ar(0,BufRateScale.kr(buf)*rate,0,BufFrames.kr(buf));
		Out.ar(out, sig);
	}).add;
	SynthDef.new(\rec, {
		arg ptrIn=0,
		micIn=0,
		buf=0;
		var ptr,
		sig;
		ptr=In.ar(ptrIn,1);
		sig=In.ar(micIn,1);
		BufWr.ar(sig,buf,ptr);
	}).add;
	SynthDef(\gran, {
		arg amp=0.5,
		buf=0,
		out=0,
		atk=1,
		rel=1,
		gate=1,
		sync=1,
		dens=40,
		baseDur=0.05,
		durRand=1,
		rate=1,
		rateRand=1,
		pan=0,
		panRand=0,
		grainEnv=(-1),
		ptrBus=0,
		ptrSampleDelay=20000,
		ptrRandSamples=5000,
		minPtrDelay=1000;
		var sig,
		env,
		densCtrl,
		durCtrl,
		rateCtrl,
		panCtrl,
		ptr,
		ptrRand,
		totalDelay,
		maxGrainDur;
		env=EnvGen.kr(
			Env.asr(
				atk,
				1,
				rel
			),
			gate,
			doneAction: 2
		);
		densCtrl=Select.ar(
			sync,
			[
				Dust.ar(
					dens
				),
				Impulse.ar(
					dens
				)
			]
		);
		durCtrl=baseDur*LFNoise1.ar(100).exprange(1/durRand,durRand);
		rateCtrl=rate.lag3(0.5)*LFNoise1.ar(100).exprange(1/rateRand,rateRand);
		panCtrl=pan+LFNoise1.kr(100).bipolar(panRand);
		ptrRand=LFNoise1.ar(100).bipolar(ptrRandSamples);
		totalDelay=max(ptrSampleDelay-ptrRand,minPtrDelay);
		ptr=In.ar(ptrBus,1);
		ptr=ptr-totalDelay;
		ptr=ptr/BufFrames.kr(buf);
		maxGrainDur=(totalDelay/rateCtrl)/SampleRate.ir;
		durCtrl=min(durCtrl,maxGrainDur);
		sig=GrainBuf.ar(
			2,
			densCtrl,
			durCtrl,
			buf,
			rateCtrl,
			ptr,
			2,
			panCtrl,
			grainEnv,
			maxGrains:16,
		);
		sig = MoogFF.ar(
			sig*env*amp,
			freq:\cutoff.kr(12000),
			gain:\resonance.kr(1)
		);
		Out.ar(out,sig);
	}).add;

//defining our sampler
	SynthDef(\PlayBufPlayer, {
		arg out=0,
		bufnum=0,
		rate=1,
		start=0,
		end=1,
		t_trig=0,
		loops=1,
		amp=0.2,
		pan=0,
		del1_pan=0,
		del2_pan=0,
		rateSlew=0.1,
		panSlew=1,
		bus=0,
		delay1_time=1,
		decay1_time=1,
		delay1_amount=0,
		delay2_time=1,
		decay2_time=1,
		delay2_amount=0,
		reverb_amount=0,
		room_size=0.5,
		damp=0.5;
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
		env=EnvGen.ar(
			Env.new(
				levels: [0,amp,amp,0],
				times: [0,duration-0.1,0.1],
			),
			gate:t_trig,
		);
		pos=Phasor.ar(
			trig:aOrB,
			rate:rate,
			start:(((rate>0)*startA)+((rate<0)*endA))*frames,
			end:(((rate>0)*endA)+((rate<0)*startA))*frames,
			resetPos:(((rate>0)*startA)+((rate<0)*endA))*frames,
		);
		snd=BufRd.ar(
			numChannels:1,
			bufnum:bufnum,
			phase:pos,
			interpolation:4,
		);
		pos2=Phasor.ar(
			trig:(1-aOrB),
			rate:rate,
			start:(((rate>0)*startB)+((rate<0)*endB))*frames,
			end:(((rate>0)*endB)+((rate<0)*startB))*frames,
			resetPos:(((rate>0)*startB)+((rate<0)*endB))*frames,
		);
		snd2=BufRd.ar(
			numChannels:1,
			bufnum:bufnum,
			phase:pos2,
			interpolation:4,
		);
		delay1=CombC.ar(
			LeakDC.ar(
				(crossfade*snd)+((1-crossfade)*snd2) * env),
			2,
			delay1_time,
			decay1_time,
			delay1_amount
		);
		delay2=CombC.ar(
			LeakDC.ar(
				(crossfade*snd)+((1-crossfade)*snd2) * env),
			2,
			delay2_time,
			decay2_time,
			delay2_amount
		);
		sig=Pan2.ar(
			FreeVerb.ar(
				MoogFF.ar(
					in: (crossfade*snd)+((1-crossfade)*snd2) * env,
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
		)  + Pan2.ar(
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
	}).add;
	s.sync;

//putting three instances of our sampler in places we can refer to later
	t = 3.collect(
		{
			Synth(\PlayBufPlayer);
		}
	);
	~micGrp=Group.new;
	~ptrGrp=Group.after(~micGrp);
	~recGrp=Group.after(~ptrGrp);
	~granGrp=Group.after(~recGroup);
	~delMic=Synth(\mic,[\in,0,\out,~micBus,\amp,0],~micGrp);
	~inMic=2.collect(
		{
			arg i;
			Synth(\mic,[\in,0,\out,~fb.index+i,\amp,0],~micGrp);
		}
	);
	Synth(\ptr,[\buf,~delBuf,\out,~ptrBus],~ptrGrp);
	Synth(\rec,[\ptrIn,~ptrBus,\micIn,~micBus,\buf,~delBuf],~recGrp);

	//modulators
	48.do({
		arg i;
		if(
			i < 16, //calibrated for panning
			{
				Ndef(i.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(2.0,16.0)).range(-1,1)
				})
			}
		);
		if(
			(i > 15) && (i < 32), //calibrated for filter cutoff
			{
				Ndef(i.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(2.0,512.0)).range(500,15000)
				})
			}
		);
		if(
			(i > 31) && (i < 48), //calibrated for filter resonance
			{
				Ndef(i.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(2.0,512.0)).range(0,3)
				})
			}
		);
	});
	s.sync;

	3.do(
		{
			arg i;
			Tdef(
				i.asSymbol, {
					var delta, start, end;
					loop {
						if(
							~rateRand[i] == 1,
							{
								~randRate[i] = ~orderedRates.choose;
								~currentRate[i] = ~randRate[i];
								("sampler " ++ (i+1) ++ " random rate: " ++ ~randRate[i]).postln;
								t[i].set(\rate, ~randRate[i])
							},
							{
								t[i].set(\rate, ~currentRate[i])
							}
						);
						if(
							~selectRand[i] == 1,
							{
								~randStart[i] = rrand(0,0.9);
								~duration[i] = [0.125,0.25,0.5,1,2,3,4,8,16].choose;
								if(
									~randStart[i] <= 0.75,
									{
										~randEnd[i] = rrand(0.01,0.25)
									},
									{
										if(
											~randStart[i] <= 0.5,
											{
												~randEnd[i] = rrand(0.01,0.5)
											},
											{
												if(
													~randStart[i] <= 0.25,
													{
														~randEnd[i] = rrand(0.01,0.75)
													},
													{
														if(
															~randStart[i] > 0.75,
															{
																~randEnd[i] = rrand(0.01,0.1)
															}
														)
													}
												)
											}
										)
									}
								);
								start = ~randStart[i];
								end = ~randEnd[i]
							},
							{
								start = ~startTime[i];
								end = ~endTime[i];
								if(
									(~endSec[i]-~startSec[i]).abs > (~timer.beatDur*0.125),
									{
										~duration[i] = ((~endSec[i]-~startSec[i]).abs*~timer.tempo*(1/~currentRate[i]).abs).round(0.125);
									},
									{
										~duration[i] = 0.125;
									}
								)
							}
						);
						delta = ~duration[i];
						t[i].set(\bufnum,d[\p][~samp[i]],\t_trig,1,\start,start,\end,end,\loops,1,);
						delta.yield;
					}
				}
			).clock_(~timer).quant_(4)
		}
	);
	~orderedRates = [(-2),(-3/2),(-1),(-1/2),(-1/4),1/4,1/2,1,3/2,2];
	~rates = [1/4,1/2,1,3/2,2].scramble;
	~durs = 15.collect(
		{
			arg i;
			~timer.beatDur*(i+1)*4
		}
	).scramble;
	~delays = 15.collect(
		{
			arg i; s.sampleRate*(~timer.beatDur*(i+1))*8
		}
	).scramble;
	~g = 15.collect({
		arg n;
		Synth(\gran, [
			\amp, 0,
			\buf, ~delBuf,
			\out, ~fb.index,
			\atk, 1,
			\rel, 1,
			\gate, 1,
			\sync, 1,
			\dens, 1/(~durs[n]*~rates[n%5]),
			\baseDur, ~durs[n],
			\durRand, 1,
			\rate, ~rates[n%5],
			\rateRand, 1,
			\pan, Ndef(n.asSymbol),
			\panRand, 0,
			\grainEnv, -1,
			\ptrBus, ~ptrBus,
			\ptrSampleDelay, ~delays[n],
			\ptrRandSamples, s.sampleRate*(~timer.beatDur*((n%8)+1))*2,
			\minPtrDelay, ~delays[n],
			\cutoff, Ndef((n+16).asSymbol),
			\resonance, Ndef((n+32).asSymbol)
		], ~granGrp;
		)
	});
}))