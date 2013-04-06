module util.mdl.parser;

debug import std.stdio;
import std.conv;
import std.array;
import std.traits;
import goldie.all;
import util.mdl.mdlparser.all;

import util.mdl.mdl;
import util.vector;
import semitwist.util.reflect;

private
{
	alias Token_mdlparser MdlToken;

	T getValue(T, TokenType)(TokenType tok)
	{
		static if(is(T == string))
			return tok.toString[1..$-1];
		else static if(is(T == Vector!(float,3)))	
		{
			auto vecTok = tok.getRequired!(MdlToken!"<Vector3>")();
			float x = to!float(vecTok.getRequired!(MdlToken!"<Real>")(0).toString);
			float y = to!float(vecTok.getRequired!(MdlToken!"<Real>")(1).toString);
			float z = to!float(vecTok.getRequired!(MdlToken!"<Real>")(2).toString);
			return vec3(x,y,z);
		}
		else static if(is(T == Vector!(float,2)))	
		{
			auto vecTok = tok.getRequired!(MdlToken!"<Vector2>")();
			float x = to!float(vecTok.getRequired!(MdlToken!"<Real>")(0).toString);
			float y = to!float(vecTok.getRequired!(MdlToken!"<Real>")(1).toString);
			return vec2(x,y);
		}		
		else static if(is(T == Vector!(int, 2)))
		{
			auto vecTok = tok.getRequired!(MdlToken!"<Vector2Int>")();
			int x = to!int(vecTok.getRequired!(MdlToken!"Integer")(0).toString);
			int y = to!int(vecTok.getRequired!(MdlToken!"Integer")(1).toString);
			return vec2i(x,y);
		}
		else static if(is(T == Vector!(uint, 6)))
		{
			auto vecTok = tok.getRequired!(MdlToken!"<Vector6Int>")();
			int x0 = to!int(vecTok.getRequired!(MdlToken!"Integer")(0).toString);
			int x1 = to!int(vecTok.getRequired!(MdlToken!"Integer")(1).toString);
			int x2 = to!int(vecTok.getRequired!(MdlToken!"Integer")(2).toString);
			int x3 = to!int(vecTok.getRequired!(MdlToken!"Integer")(3).toString);
			int x4 = to!int(vecTok.getRequired!(MdlToken!"Integer")(4).toString);
			int x5 = to!int(vecTok.getRequired!(MdlToken!"Integer")(5).toString);			
			return Vector!(uint, 6)(x0, x1, x2, x3, x4, x5);
		}		
		else
		{
			return to!T(tok.toString);
		}
	}

	string generateTokenSwitch(string prefix, string switchVar, AggregateType, string aggregateVar, string tokenVar, Names...)()
	{
		auto ret = appender!string();
		ret.put("switch("~switchVar~")\n{\n");

		foreach(name; Names)
		{
			static assert(is(typeof(name) == string));
			ret.put("case \"<"~prefix~name~"Val>\":\n{\n");
			ret.put(aggregateVar~"."~name~" = getValue!("~typeof(mixin(fullyQualifiedName!AggregateType~"."~name)).stringof~")("~tokenVar~");\n");
			ret.put("break;\n}\n");
		}

		ret.put("default:\n}");
		return ret.data;
	}

	void getModelSection(MdlToken!"<ModelSection>" tok, ref MdlModel model)
	{
		alias MdlToken!"<ModelSection>" CurToken1;
		model.ModelName = getValue!string(tok.getRequired!(MdlToken!"<ModelName>"));

		void getModelVars(MdlToken!"<ModelVarsList>" tokVarList)
		{
			foreach(tok; traverse(tokVarList))
			{
				//pragma(msg, generateTokenSwitch!("Model", "tok.name", "NumGeosets", "NumGeosetAnims")());
				mixin(generateTokenSwitch!("Model", "tok.name", MdlModel, "model", "tok",
					"NumGeosets", 
					"NumGeosetAnims",
					"NumLights",
					"NumHelpers",
					"NumBones",
					"NumAttachments",
					"NumParticleEmitters",
					"NumParticleEmitters2",
					"NumRibbonEmitters",
					"NumEvents",
					"BlendTime",
					"MinimumExtent",
					"MaximumExtent",
					"BoundsRadius"
					)());
			}
		}
		getModelVars(tok.getRequired!(MdlToken!"<ModelVarsList>")());
	}

	MdlModel.SequenceAnimation getAnimationSection(string name, MdlToken!"<AnimationSection>" tok)
	{
		auto anim = MdlModel.SequenceAnimation();
		anim.AnimationName = name;
		anim.NonLooping = false;

		foreach(elemTok; traverse(tok))
		{
			if(elemTok.name == "<AnimNonLooping>")
			{
				anim.NonLooping = true;
				continue;
			}

			/*pragma(msg, generateTokenSwitch!("Anim", "elemTok.name", MdlModel.SequenceAnimation, "anim", "elemTok",
				"Interval",
				"Rarity", 
				"MoveSpeed",
				"MinimumExtent",
				"MaximumExtent",
				"BoundsRadius",
				)());*/
			mixin(generateTokenSwitch!("Anim", "elemTok.name", MdlModel.SequenceAnimation, "anim", "elemTok", 
				"Interval",
				"Rarity", 
				"MoveSpeed",
				"MinimumExtent",
				"MaximumExtent",
				"BoundsRadius",
				)());	
		}

		return anim;
	}

	void getSequencesSection(MdlToken!"<SequencesSection>" seqTok, ref MdlModel model)
	{
		auto tok = seqTok.getRequired!(MdlToken!"<AnimSectionsList>")();
		foreach(animTok; traverse!( isAnyType!(MdlToken!"<AnimationSection>", MdlToken!"<AnimSectionsList>") )(tok))
		{
			if(animTok.name == "<AnimationSection>")
			{
				string name = getValue!string(animTok.getRequired!(MdlToken!"<AnimationName>"));
				model.SequenceAnimations[name] = getAnimationSection(name, cast(MdlToken!"<AnimationSection>")animTok);
			}
		}
	}

	void getGlobalSequencesSection(MdlToken!"<GlobalSequencesSection>" seqTok, ref MdlModel model)
	{
		size_t count = getValue!size_t(seqTok.getRequired!(MdlToken!"<GlobalSequencesCount>")());
		model.GlobalSequencesDurations = new size_t[count];
		size_t i = 0;
		foreach(durTok; traverse!( isAnyType!(MdlToken!"<GlobalSequencesVarsList>", MdlToken!"<GlobalSequenceDuration>"))(seqTok))
		{
			if(durTok.name == "<GlobalSequenceDuration>")
			{
				model.GlobalSequencesDurations[i++] = getValue!size_t(durTok);
			}
		}
	}

	MdlModel.BitmapTexture getBitmapTexture(MdlToken!"<BitmapSection>" bitmapTok)
	{
		MdlModel.BitmapTexture bitmap;

		foreach(tok; traverse(bitmapTok))
		{
			if(tok.name == "<BitmapWrapWidth>")
			{
				bitmap.WrapWidth = true;
				continue;
			} 
			else if(tok.name == "<BitmapWrapHeight>")
			{
				bitmap.WrapHeight = true;
				continue;
			}

			mixin(generateTokenSwitch!("Bitmap", "tok.name", MdlModel.BitmapTexture, "bitmap", "tok", 
				"Image",
				"ReplaceableId"
				)());
		}

		return bitmap;
	}

	void getTexturesSection(MdlToken!"<TexturesSection>" texTok, ref MdlModel model)
	{
		size_t count = getValue!size_t(texTok.getRequired!(MdlToken!"<TexturesCount>")());
		model.Textures = new model.BitmapTexture[count];
		size_t i = 0;
		foreach(bitmapTok; traverse!( isAnyType!(MdlToken!"<BitmapSectionsList>", MdlToken!"<BitmapSection>"))(texTok))
		{
			if(bitmapTok.name == "<BitmapSection>")
			{
				model.Textures[i++] = getBitmapTexture(cast(MdlToken!"<BitmapSection>")bitmapTok);
			}
		}
	}

	MdlModel.Material.Layer.FilterModeT convert2FilterMode(string str)
	{
		alias MdlModel.Material.Layer.FilterModeT RetEnum;
		switch(str)
		{
			case "None":
				return RetEnum.NONE;
			case "Transparent":
				return RetEnum.TRANSPARENT;
			case "Blend":
				return RetEnum.BLEND;
			case "Additive":
				return RetEnum.ADDITIVE;
			case "AddAlpha":
				return RetEnum.ADD_ALPHA;
			case "Modulate":
				return RetEnum.MODULATE;
			case "Modulate2x":
				return RetEnum.MODULATE_2X;
			default:
				return RetEnum.NONE;
		}
	}

	MdlModel.Material.Layer.AnimationTypeT getAnimationType(string str)
	{
		alias MdlModel.Material.Layer.AnimationTypeT RetEnum;
		switch(str)
		{
			case "DontInterp":
				return RetEnum.DONT_INTERP;
			case "Linear":
				return RetEnum.LINEAR;
			default:
				return RetEnum.DONT_INTERP;
		}
	}

	MdlModel.Material.Layer getLayerSection(MdlToken!"<LayerSection>" layerTok)
	{
		MdlModel.Material.Layer layer;

		auto range = traverse(layerTok);
		foreach(tok; range)
		{
			if(tok.name == "<LayerUnshaded>")
			{
				layer.Unshaded = true;
				continue;
			}
			else if(tok.name == "<LayerUnfogged>")
			{
				layer.Unfogged = true;
				continue;
			}
			else if(tok.name == "<LayerTwoSided>")
			{
				layer.TwoSided = true;
				continue;
			}
			else if(tok.name == "<LayerSphereEnvMap>")
			{
				layer.SphereEnvMap = true;
				continue;
			}
			else if(tok.name == "<LayerNoDepthTest>")
			{
				layer.NoDepthTest = true;
				continue;
			}
			else if(tok.name == "<LayerNoDepthSet>")
			{
				layer.NoDepthSet = true;
				continue;
			}
			else if(tok.name == "<FilterModeEnum>")
			{
				layer.FilterMode = convert2FilterMode(tok.toString);
				continue;
			} 
			else if(tok.name == "<LayerTextureID>")
			{
				assert(layer.staticTexture, "Unexpected static textureid in layer after dynamic texture!");
				layer.staticTexture = true;
				layer.Texture.TextureID = getValue!uint(tok.getRequired!(MdlToken!"<LayerTextureIDVal>")());
			}
			else if(tok.name == "<LayerTextureIDSection>")
			{
				layer.staticTexture = false;
				layer.Texture.TextureID = getValue!uint(tok.getRequired!(MdlToken!"<LayerTextureIDVal>")());
				layer.Texture.Type = getAnimationType(tok.getRequired!(MdlToken!"<AnimationType>")().toString);

				foreach(keyTok; traverse(tok))
				{
					if(keyTok.name == "<TextureAnimationKey>")
					{
						layer.Texture.Frames[getValue!uint(keyTok.getRequired!(MdlToken!"Integer")())] =
							getValue!float(keyTok.getRequired!(MdlToken!"<Real>")());
					}
				}

				range.skip();
				continue;
			}
			else if(tok.name == "<LayerAlpha>")
			{
				assert(layer.staticAlpha, "Unexpected static alpha in layer after dynamic alpha!");
				layer.staticAlpha = true;
				layer.StaticAlphaValue = getValue!float(tok.getRequired!(MdlToken!"<LayerAlphaVal>")());
				continue;
			}
			else if(tok.name == "<LayerAlphaSection>")
			{
				layer.staticAlpha = false;
				layer.alpha.Type = getAnimationType(tok.getRequired!(MdlToken!"<AnimationType>")().toString);

				foreach(keyTok; traverse(tok))
				{
					if(keyTok.name == "<AlphaAnimationKey>")
					{
						layer.alpha.Frames[getValue!uint(keyTok.getRequired!(MdlToken!"Integer")())] =
						getValue!float(keyTok.getRequired!(MdlToken!"<Real>")());
					}
				}

				range.skip();
				continue;
			}
		}
		return layer;
	}

	MdlModel.Material getMaterial(MdlToken!"<MaterialSection>" matTok)
	{
		MdlModel.Material mat;
		mat.Layers = new MdlModel.Material.Layer[0];

		auto range = traverse(matTok);
		foreach(tok; range)
		{
			if(tok.name == "<MaterialConstantColor>")
			{
				mat.ConstantColor = true;
				continue;
			}
			else if(tok.name == "<MaterialSortPrimsFarZ")
			{
				mat.SortPrimsFarZ = true;
				continue;
			}
			else if(tok.name == "<MaterialFullResolution>")
			{
				mat.FullResolution = true;
				continue;
			}
			else if(tok.name == "<MaterialPriorityPlaneVal>")
			{
				mat.PriorityPlane = getValue!uint(tok);
				continue;
			}
			else if(tok.name == "<LayerSection>")
			{
				mat.Layers ~= getLayerSection(cast(MdlToken!"<LayerSection>")tok);
				//range.skip();
				continue;
			}
		}
		return mat;
	}

	void getMaterialsSection(MdlToken!"<MaterialsSection>" matsTok, ref MdlModel model)
	{
		size_t count = getValue!size_t(matsTok.getRequired!(MdlToken!"<MaterialsCount>")());
		model.Materials = new model.Material[count];
		size_t i = 0;
		foreach(tok; traverse!(isAnyType!(MdlToken!"<MaterialsList>", MdlToken!"<MaterialSection>"))(matsTok))
		{
			if(tok.name == "<MaterialSection>")
			{
				model.Materials[i++] = getMaterial(cast(MdlToken!"<MaterialSection>")tok);
			}
		}
	}


	MdlModel.Geoset getGeoset(MdlToken!"<GeosetSection>" geoTok)
	{
		MdlModel.Geoset geoset;

		auto range = traverse(geoTok);
		foreach(tok; range)
		{
			if(tok.name == "<GeosetUnselectable>")
			{
				geoset.Unselectable = true;
				continue;
			}
			else if(tok.name == "<GeosetVerticesSection>")
			{
				size_t count = getValue!size_t(tok.getToken!"<GeosetVerticesCount>"());
				geoset.Vertices = new vec3[count];
				size_t i = 0;
				foreach(vertTok; traverse(tok))
				{
					if(vertTok.name == "<GeosetVertice>")
					{
						geoset.Vertices[i++] = getValue!vec3(vertTok);
					}
				}
				range.skip();
				continue;
			}
			else if(tok.name == "<GeosetNormalsSection>")
			{
				size_t count = getValue!size_t(tok.getToken!"<GeosetNormalsCount>"());
				geoset.Normals = new vec3[count];
				size_t i = 0;
				foreach(vertTok; traverse(tok))
				{
					if(vertTok.name == "<GeosetNormal>")
					{
						geoset.Normals[i++] = getValue!vec3(vertTok);
					}
				}				
				range.skip();
				continue;
			}
			else if(tok.name == "<GeosetTVerticesSection>")
			{
				size_t count = getValue!size_t(tok.getToken!"<GeosetTVerticesCount>"());
				geoset.TVertices = new vec2[count];
				size_t i = 0;
				foreach(vertTok; traverse(tok))
				{
					if(vertTok.name == "<GeosetTVertice>")
					{
						geoset.TVertices[i++] = getValue!vec2(vertTok);
					}
				}
				range.skip();
				continue;
			}
			else if(tok.name == "<GeosetVertexGroupSection>")
			{
				assert(geoset.Vertices.length != 0, "Geoset vertices group section appears before vertices section!");
				geoset.Groups = new uint[geoset.Vertices.length];
				size_t i = 0;
				foreach(groupTok; traverse(tok))
				{
					if(groupTok.name == "<GeosetVertexGroupVal>")
					{
						geoset.Groups[i] = getValue!uint(groupTok);
					}
				}

				range.skip();
				continue;
			}
			else if(tok.name == "<GeosetFacesSection>")
			{
				geoset.Triangles = new Vector!(uint, 6)[0];
				auto triangRange = traverse(tok);
				foreach(trianTok; traverse(tok))
				{
					if(trianTok.name == "<FacesTrianglesSection>")
					{
						triangRange.skip();

						foreach(triangleElemTok; traverse(trianTok))
						{
							if(triangleElemTok.name == "<GeosetTriangle>")
							{
								geoset.Triangles ~= getValue!(Vector!(uint, 6))(triangleElemTok);
							}
						}
					}
				}
				range.skip();
				continue;
			}
			else if(tok.name == "<GeosetGroupsSection>")
			{
				range.skip();
				continue;
			}		
			else if(tok.name == "<GeosetAnimSection>")
			{
				range.skip();
				continue;
			}	

			mixin(generateTokenSwitch!("Geoset", "tok.name", MdlModel.Geoset, "geoset", "tok", 
				"MinimumExtent",
				"MaximumExtent",
				"BoundsRadius",
				"MaterialID",
				"SelectionGroup"
				)());
		}

		return geoset;
	}

	void getGeosetSections(MdlToken!"<GeosetSections>" geosetsTok, ref MdlModel model)
	{
		model.Geosets = new MdlModel.Geoset[0];
		foreach(tok; traverse!( isAnyType!(MdlToken!"<GeosetSections>", MdlToken!"<GeosetSection>") )(geosetsTok))
		{
			if(tok.name == "<GeosetSection>")
			{
				model.Geosets ~= getGeoset(cast(MdlToken!"<GeosetSection>")tok);
			}
		}
	}

	MdlToken!tokname getToken(string tokname)(Token tok)
	{
		return tok.getRequired!(MdlToken!tokname)();
	}

	MdlModel getModel(MdlToken!"<Everything>" root)
	{
		MdlModel model = MdlModel();

		model.FormatVersion = getValue!uint(root.getRequired!(
			MdlToken!"<VersionSection>", 
			MdlToken!"<FormatVersion>", 
			MdlToken!"<FormatVersionVal>")());
		getModelSection(root.getToken!"<ModelSection>"(), model);
		getSequencesSection(root.getToken!"<SequencesSection>"(), model);
		getGlobalSequencesSection(root.getToken!"<GlobalSequencesSection>"(), model);
		getTexturesSection(root.getToken!"<TexturesSection>"(), model);
		getMaterialsSection(root.getToken!"<MaterialsSection>"(), model);
		getGeosetSections(root.getToken!"<GeosetSections>", model);
		return model;
	}
}

version(unittest)
{
	import std.stdio;
	auto testMdl = 
`
// сам комментарий
//============ © ScorpioT1000//
// Общие параметры
//=======================//
Version { //версия моделей
    FormatVersion 800, //остается 800
}

Model "Name" { // название модели
    NumGeosets 1, // количество мешей
    NumGeosetAnims 2, // количество анимаций видимости
    NumLights 1, // количество источников света
    NumHelpers 1, // количество помощников
    NumBones 5, // количество костей 
    NumAttachments 3, // количество прикреплений 
    NumParticleEmitters 1, // количество старых источников частиц
    NumParticleEmitters2 1, // количество источников частиц 2
    NumRibbonEmitters 1, // количество источников следа
    NumEvents 2, // количество событий 
    BlendTime 150, // время смешения 
    MinimumExtent { -27.125, -23.125, 0.225586 }, // минимальные границы модели 
    MaximumExtent { 22, 24.25, 98.5 }, // максимальные границы модели 
    BoundsRadius 34.4232, // радиус, при котором модель все еще видна, когда центр уходит за границы экрана
}

Sequences 2 { //последовательности
    Anim "Stand" { // название анимации 
        Interval { 0, 3333 },  // временной интервал 
        Rarity 1.5, // частота воспроизведения
        MoveSpeed 80, // скорость перемещения
        NonLooping, // не повторять сначала
        MinimumExtent { -27.125, -23.125, 0.225586 }, //минимальные
        MaximumExtent { 22, 24.25, 98.5 }, //и максимальные границы для анимации
        BoundsRadius 34.4232, //радиус видимости на экране для анимации
    }
    Anim "Walk" {
        Interval { 3333, 5555 },
        Rarity 0.5,
        MoveSpeed 80, // скорость перемещения
        NonLooping, // не повторять сначала
        MinimumExtent { -27.125, -23.125, 0.225586 }, //минимальные
        MaximumExtent { 22, 24.25, 98.5 }, //и максимальные границы для анимации
        BoundsRadius 34.4232, //радиус видимости на экране для анимации
    }
}

GlobalSequences 2 { // глобальные анимации
    Duration 967, // длительность анимации 0
    Duration 467, // длительность анимации 1
    //итд
}


Textures 1 { // текстуры
    Bitmap { // является изображением
        Image "Textures\Goldmine.blp", // путь в архиве или в папке с моделью
        WrapWidth, // сохранять ширину
        WrapHeight, // сохранять высоту
        // текстура замощена на таблице, и если стоят эти флаги,
        // то можно перейти на соседние копии текстуры, иначе там будет черная область
        ReplaceableId 1, // заменяемая текстура, значение от 1 до 32
    }
}

Materials 1 { 
    Material { 
        ConstantColor,
        SortPrimsFarZ,
        FullResolution, 
        PriorityPlane 2,
        
        Layer { 
            FilterMode None, 
            Unshaded, 
            Unfogged, 
            static TextureID 0, 
            TwoSided,
            SphereEnvMap,
            NoDepthTest,
            NoDepthSet,
            Alpha 2 {
                Linear, 
                0: 0, 
                1000: 1,
            }
            //static Alpha 0.7,
        }
        
        Layer { 
            TextureID 2 { 
                DontInterp, 
                0: 0,
                1000: 1,
            }
        }
        
    }
}

TextureAnims 1 { //анимации текстур
    TVertexAnim { //анимация текстурных вершин
        Translation 2 { //перемещение
            DontInterp, //тип
            0: { 0, 0, 0 },
            1: { 1, 1, 1 },
        }
        
    }
}

Geoset { 
    Vertices 4 {
        { -22.75, 12.9375, 42.25 },
        { -13.4375, 12.9375, 43 },
        { -22.75, 18.75, 41 },
        { -13.375, 18.75, 41.75 },
    }
    Normals 4 { 
        { -0.172104, -0.93708, -0.303745 },
        { 0.625556, -0.752452, -0.206145 },
        { -0.807936, 0.334689, -0.484998 },
        { 0.459442, 0.748768, -0.477765 },
    }
    TVertices 4 { 
        { 0, 0 },
        { 0, 0.85 },
        { 1, 0 },
        { 1, 1 },
    }
    VertexGroup { 
        0, 
        0, 
        0,
        0,
    }
    Faces 1 6 {
        Triangles {
            { 0, 1, 2, 3, 2, 1 },
        }
    }
    Groups 1 1 {
        Matrices { 0 }, 
        //Matrices { 0, 1 },
    }
    
    MinimumExtent { -24.875, 12.9375, 41 }, 
    MaximumExtent { -13.375, 24.25, 98.5 }, 
    BoundsRadius 29.1094, 
    Anim { 
        MinimumExtent { -24.875, 12.9375, 41 },
        MaximumExtent { -13.375, 24.25, 98.5 },
        BoundsRadius 29.1094,
    }

    MaterialID 0, 
    SelectionGroup 0, 
}
`;
}
unittest
{
	write("Testing mdl parser... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");	

	try
	{
		auto parseTree = language_mdlparser.parseCode(testMdl).parseTree;
		auto model = getModel(parseTree);
		writeln(model);
	}
	catch(ParseException e)
	{
		writeln(e.msg);
		assert(false, "Mdl parser failed!");
	}

}