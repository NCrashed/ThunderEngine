//          Copyright Gushcha Anton 2013.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
module client.model.mdlcodec;

import util.codecmng;
import util.serialization.serializer;
import util.codec;
import util.standarts.model;
import util.mdl.mdl;
import util.mdl.parser;
import util.vector;


class MdlCodec : Codec 
{
	public
	{
		enum DEFAULT_SCALING = 0.01f;

		string type() @property const
		{
			return "mdl";
		}

		string standart() @property const
		{
			return "model";
		}

		Stream decode(Stream data)
		{
			MdlModel mdlModel = parseMdlInput(data);
			TempModel model;

			void swapYZandScale(vec3[] vecs)
			{
				foreach(ref v; vecs)
				{
					float temp = v.z;
					v.z = v.y;
					v.y = temp;
					
					v.x = v.x * DEFAULT_SCALING;
					v.y = v.y * DEFAULT_SCALING;
					v.z = v.z * DEFAULT_SCALING;
				}
			}

			void swapYZ(vec3[] vecs)
			{
				foreach(ref v; vecs)
				{
					float temp = v.z;
					v.z = v.y;
					v.y = temp;
				}
			}

			model.meshes = new TempModel.MeshInfo[mdlModel.Geosets.length];
			foreach(i, ref geoset; mdlModel.Geosets)
			{
				with(model.meshes[i])
				{
					vecs = geoset.Vertices.dup; 
					swapYZandScale(vecs);
					normals = geoset.Normals.dup; 
					swapYZ(normals);
					uvs = geoset.TVertices.dup;

					indexes = new vec3ui[geoset.Triangles.length / 3];
					foreach(j, ref indVec; indexes)
					{
						indVec.x = geoset.Triangles[j*3 + 0];
						indVec.y = geoset.Triangles[j*3 + 1];
						indVec.z = geoset.Triangles[j*3 + 2];
					}
				}
			}

			return serialize!BinaryArchive(model.finalize());
		}

		Stream code(Stream data)
		{
			throw new Exception("Mdl coding isn't implemented!");
		}
	}
}

static this()
{
	CodecMng.getSingleton().registerCodec(new MdlCodec);
}