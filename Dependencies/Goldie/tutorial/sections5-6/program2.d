import std.bigint;
import std.conv;
import std.stdio;

import goldie.all; // Import GoldieLib itself
import commas.all; // Import our commas language

enum Size { Large, Small }

struct Element
{
	string ident;
	BigInt integer;
	
	string toString()
	{
		if(ident)
			return "Ident:   "~ident;
		else
		{
			string str;
			integer.toString((const(char)[] s) { str ~= s; }, "");
			return "Integer: "~str;
		}
	}
}

struct Commas
{
	Size size;
	Element[] elements;

	string toString()
	{
		string str = to!string(size);
		foreach(elem; elements)
		{
			str ~= "\n";
			str ~= elem.toString();
		}
		return str;
	}
}

alias Token_commas Tok;

int main(string[] args)
{
	try
	{
		auto parseTree = language_commas.parseFile(args[1]).parseTree;
		auto commas = toCommas(parseTree);
		writeln(commas);
	}
	catch(ParseException e)
	{
		writeln(e.msg);
		return 1;
	}

	return 0;
}

Commas toCommas(Tok!"<Everything>" root)
{
	Commas commas;

	// Determine size
	auto tokSize = root.get!(Tok!"<Size>")();
	if( cast(Tok!("<Size>", "Large")) tokSize )
		commas.size = Size.Large;
	else
		commas.size = Size.Small;
	
	// Get elements
	auto tokList = root.get!(Tok!"<List>")();
	commas.elements = toElements(tokList);
	
	return commas;
}

Element[] toElements(Tok!"<List>" tokList)
{
	Element[] elems;

	// Traverse each token in tokList
	// (using preorder tree traversal: first the parent, then the children)
	foreach(Token token; traverse(tokList))
	{
		// If the token is an Ident or Integer,
		// convert it to Element and append it to the array.
		if(auto tokElem = cast(Tok!"Ident") token)
			elems ~= toElement(tokElem);
		else if(auto tokElem = cast(Tok!"Integer") token)
			elems ~= toElement(tokElem);
	}

	return elems;
}

Element toElement(Tok!"Ident" tokElem)
{
	return Element( tokElem.toString() );
}

Element toElement(Tok!"Integer" tokElem)
{
	auto str = tokElem.toString();

	// Integer "{zero}"?
	if(str == "{zero}")
		return Element(null, BigInt("0"));
	
	// Normal integer
	return Element(null, BigInt(str));
}
