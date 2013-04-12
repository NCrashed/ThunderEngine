//          Copyright Gushcha Anton 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
// Written in the D programming language.
/**
*	CTFE finite automata generator.
*/
module util.parsing.automata;

import std.traits;
import std.algorithm;
import std.array;
import std.conv;

/**
*	Struct wich fully defines deterministic finite state machine.
*/
mixin template DFAGenerator(string name, char_t, state_t, 
	string statesStr, state_t startState, string endStatesStr, state_t errorState, rules...)
	if(isSomeChar!(char_t))
{
	mixin("template "~name~"()"~q{
	{
		static assert(isSomeChar!(char_t), "NFAInfo: char_t must be char type!");
		static assert(states.length >= endStates.length, "End states greater then all states set!");
		static assert(isStateInStates(startState), "Start state is not in all states set!");
		static assert(checkEndStates(), "One of the end state is not in all states set!");
		static assert(validateRules!rules, "One of the automata transation has syntax error!");

		bool validate(immutable(char_t[]) str)
		{
			state_t state = startState;
			foreach(ch; str)
			{
				state = transfer(state, ch);
				if(state == errorState)
					return false;
			}
			return isEndState(state);
		}

		state_t transfer(state_t curState, char_t way)
		{
			//pragma(msg, generateStateSwitch!("curState", "way", rules));
			mixin(generateStateSwitch!("curState", "way", rules));
		}

		package
		{
			static state_t[] states() @property
			{
				return mixin(statesStr);
			}

			static state_t[] endStates() @property
			{
				return mixin(endStatesStr);
			}

			static bool isEndState(state_t state)
			{
				foreach(endState; endStates)
				{
					if(endState == state)
						return true;
				}
				return false;
			}
		}
		private
		{
			template validateRules(strs...)
			{
				bool validateRule(string str)
				{
					scope(failure) {return false;}
					string[] splt = array(splitter(str, '-'));
					if (splt.length != 3) return false;

					to!state_t(splt[0]);
					to!state_t(splt[2]);
					to!char_t(splt[1]);
					return true;
				}

				static if(strs.length == 1)
				{
					enum validateRules = validateRule(strs[0]);
				}
				else static if(strs.length == 0)
				{
					enum validateRules = true;
				} 
				else
				{
					enum validateRules = validateRule(strs[0]) && validateRules!(strs[1..$]);
				}
			}

			template getRulesForState(state_t state, strs...)
			{
				bool checkRule(string str)
				{
					string[] splt = array(splitter(str, '-'));
					return to!state_t(splt[0]) == state;
				}

				template filterRules(curRules...)
				{
					static if(curRules.length == 0)
					{
						enum filterRules = [];
					}
					else static if(curRules.length == 1)
					{
						static if(checkRule(curRules[0]))
							enum filterRules = curRules[0];
						else
							enum filterRules = [];
					} 
					else
					{
						static if(checkRule(curRules[0]))
						{
							enum prefilter = filterRules!(curRules[1..$]);
							static if(prefilter.length == 0)
								enum filterRules = [curRules[0]];
							else
								enum filterRules = [curRules[0]]~prefilter;
						}
						else
							enum filterRules = filterRules!(curRules[1..$]);
					}
				}

				enum getRulesForState = filterRules!(strs);
			}

			static state_t getSourceState(string rule)
			{
				scope(failure) return errorState;
				string[] splt = array(splitter(rule, '-'));
				return to!state_t(splt[0]);
			}

			static state_t[] getUniqStates(state_t filterStates[])
			{
				state_t[] ret = new state_t[0];

				bool isInStates(state_t state)
				{
					foreach(st; ret)
						if(st == state)
							return true;
					return false;
				}

				foreach(state; filterStates)
				{
					if(!isInStates(state))
						ret ~= state;
				}
				return ret;
			}

			static char_t getRuleChar(string rule)
			{
				string[] splt = array(splitter(rule, '-'));
				return to!char_t(splt[1]);
			}

			static state_t getRuleDist(string rule)
			{
				string[] splt = array(splitter(rule, '-'));
				return to!state_t(splt[2]);				
			}

			static string[] getRulesByChar(char_t way, string[] someRules)
			{
				string[] ret = new string[0];
				foreach(rule; someRules)
				{
					if(getRuleChar(rule) == way)
					{
						ret ~= rule;
					}
				}
				return ret;
			}

			static char_t[] getRulesChars(string[] someRules)
			{
				char_t[] ret = new char_t[0];
				bool isInRet(char_t way)
				{
					foreach(ch; ret)
					{
						if(ch == way)
							return true;
					}
					return false;
				}

				foreach(rule; someRules)
				{
					char_t ch = getRuleChar(rule);
					if(!isInRet(ch))
						ret ~= ch;
				}
				return ret;
			}

			template generateCharSwitch(string charVar, filterRulesRaw...)
			{
				static if(is(typeof(filterRulesRaw[0]) == string))
					enum filterRules = [filterRulesRaw];
				else
					enum filterRules = filterRulesRaw[0];

				template generateHead()
				{
					enum generateHead = "\t\tswitch("~charVar~")\n\t\t{\n";
				}
				template generateItems(charsRaw...)
				{	
					template generateItem(finalRulesRaw...)
					{
						template generateItemHead(char_t caseChar)
						{
							enum generateItemHead = "\t\t\tcase('"~caseChar~"'):\n\t\t\t{\n";
						}
						template generateItemBody(state_t distState)
						{
							enum generateItemBody = "\t\t\t\treturn "~to!string(distState)~";\n\t\t\t}\n";
						}

						enum finalRules = finalRulesRaw[0];
						static if(finalRules.length == 0)
							enum generateItem = "";
						else	
							enum generateItem = generateItemHead!(getRuleChar(finalRules[0])) ~ 
								generateItemBody!(getRuleDist(finalRules[0])) ~ generateItem!(finalRules[1..$]);
					}

					enum chars = charsRaw[0];
					static if(chars.length == 0)
					{
						enum generateItems = "";
					}
					else
					{
						enum generateItems = generateItem!(getRulesByChar(chars[0], filterRules))~generateItems!(chars[1..$]);
					}
				}
				template generateFoot()
				{
					enum generateFoot = "\t\t\tdefault:\n\t\t\t{\n\t\t\t\treturn "~to!string(errorState)~";\n\t\t\t}\n\t\t}\n";
				}

				static if(filterRules.length == 0)
				{
					enum generateCharSwitch = "";
				}
				else
				{
					enum generateCharSwitch = generateHead!()~generateItems!(getRulesChars(filterRules))~generateFoot!();
				}
			}

			template generateStateSwitch(string stateVar, string charVar, strs...)
			{
				template generateHead()
				{
					enum generateHead = "switch("~stateVar~")\n{\n";
				}
				template generateItems(filterStatesRaw...)
				{
					enum filterStates = filterStatesRaw[0];
					template generateItemHead(state_t state)
					{
						enum generateItemHead = "\tcase("~to!string(state)~"):\n\t{\n";
					}
					template generateItem(state_t state)
					{
						enum generateItem = generateCharSwitch!(charVar, getRulesForState!(state, rules));
					}
					template generateItemFoot()
					{
						enum generateItemFoot = "\t}\n";
					}

					static if(filterStates.length == 0)
					{
						enum generateItems = generateDefault!();
					} 
					else
					{
						enum generateItems = generateItemHead!(filterStates[0]) ~ generateItem!(filterStates[0])
							~ generateItemFoot!() ~ generateItems!(filterStates[1..$]);
					}

				}
				template generateDefault()
				{
					enum generateDefault = "\tdefault:\n\t{\n\t\treturn "~to!string(errorState)~";\n\t}\n";
				}
				template generateFoot()
				{
					enum generateFoot = "}\n";
				}

				enum generateStateSwitch = generateHead!() ~ generateItems!(getUniqStates(states)) ~ generateFoot!();
			}

			debug bool isStateInStates(state_t st)
			{
				foreach(state; states)
				{
					if(state == st)
					{
						return true;
					}
				}
				return false;			
			}

			debug static bool checkEndStates()
			{
				foreach(endState; endStates)
				{
					if(!isStateInStates(endState))
					{
						return false;
					}
				}
				return true;
			}
		}
	}});
}

version(unittest)
{
	mixin DFAGenerator!("TestDFA1", char, uint, "[1,2,3]", 1, "[1,2]", 0,
		"1-a-2",
		"1-b-3",
		"2-a-3",
		"3-b-2",
		);

	mixin DFAGenerator!("TestDFA2", char, uint, "[1,2,3]", 1, "[2]", 0,
		"1-a-2",
		"1-b-3",
		"2-a-3",
		"3-b-2",
		);	
}
unittest
{
	assert(TestDFA1!().validate("aab"), 	"DFA1 test 1 failed");
	assert(TestDFA1!().validate(""), 		"DFA1 test 2 failed");
	assert(!TestDFA1!().validate("aabb"), 	"DFA1 test 3 failed");
	assert(!TestDFA1!().validate("aaba"), 	"DFA1 test 4 failed");

	assert(!TestDFA2!().validate(""), "DFA2 test 1 failed");
}