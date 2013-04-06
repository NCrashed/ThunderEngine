module util.mdl.mdl;

import util.vector;

struct MdlModel
{
	uint FormatVersion;

	string ModelName;
    uint NumGeosets; 			// количество мешей
    uint NumGeosetAnims; 		// количество анимаций видимости
    uint NumLights; 			// количество источников света
    uint NumHelpers; 			// количество помощников
    uint NumBones; 				// количество костей 
    uint NumAttachments; 		// количество прикреплений 
    uint NumParticleEmitters; 	// количество старых источников частиц
    uint NumParticleEmitters2;  // количество источников частиц 2
    uint NumRibbonEmitters; 	// количество источников следа
    uint NumEvents; 			// количество событий 
    float BlendTime = 0.0f; 	// время смешения 
    vec3 MinimumExtent; 		// минимальные границы модели 
    vec3 MaximumExtent; 		// максимальные границы модели 
    float BoundsRadius; 		// радиус, при котором модель все еще видна, когда центр уходит за границы экрана	

    struct SequenceAnimation
    {
    	string AnimationName;

    	vec2i Interval;
    	float Rarity;
    	float MoveSpeed;
    	vec3  MinimumExtent;
    	vec3  MaximumExtent;
    	float BoundsRadius;
    	bool  NonLooping;
    }
    SequenceAnimation[string] SequenceAnimations;
    size_t[] GlobalSequencesDurations;

    struct BitmapTexture
    {
    	string 	Image;
    	bool 	WrapWidth 	= false;
    	bool	WrapHeight	= false;    	
    	uint	ReplaceableId;
    }
    BitmapTexture[]	Textures;

    struct Material
    {
    	bool ConstantColor;
    	bool SortPrimsFarZ;
    	bool FullResolution;
    	uint PriorityPlane;

    	struct Layer
    	{
    		enum FilterModeT
    		{
    			NONE,
    			TRANSPARENT,
    			BLEND,
    			ADDITIVE,
    			ADD_ALPHA,
    			MODULATE,
    			MODULATE_2X
    		}
    		FilterModeT FilterMode;

    		enum AnimationTypeT
    		{
    			LINEAR,
    			DONT_INTERP
    		}

    		bool Unshaded = false;
    		bool Unfogged = false;

    		struct DynamicTexture
    		{
    			uint TextureID;
    			AnimationTypeT Type;
    			float[uint] Frames;
    		}
    		bool staticTexture = true;
    		DynamicTexture Texture;

    		bool TwoSided = false;
    		bool SphereEnvMap = false;
    		bool NoDepthTest = false;
    		bool NoDepthSet = false;

    		struct DynamicAlpha
    		{
    			AnimationTypeT Type;
    			float[uint] Frames;
    		}
    		bool staticAlpha = true;
    		DynamicAlpha alpha;
    		float StaticAlphaValue;

    		uint TVertexAnimId = uint.max;
    	}
    	Layer[] Layers;
    }
    Material[] Materials;

    struct Geoset
    {
        vec3 MinimumExtent;
        vec3 MaximumExtent;
        float BoundsRadius = 0.0f;
        uint MaterialID;
        uint SelectionGroup;
        bool Unselectable = false;

        vec3[]              Vertices;
        vec3[]              Normals;
        vec2[]              TVertices;
        uint[]              Groups;
        Vector!(uint, 6)[]  Triangles;
    }
    Geoset[] Geosets;    
}