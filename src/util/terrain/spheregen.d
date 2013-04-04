//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
module util.terrain.spheregen;

/// Генератор эллипсоидов
/**
*	Ландшафтный генератор, который умеет создавать сферы и эллипсоиды.
*/
class SphereGenerator
{
	/**
	*	Создание эллипсоида на основе размеров по каждой оси (x,y,z).
	*	С помощью $(B getValFunc) можно заполнять фигуру различными значениями.
	*/
	static T[][][] generate(T)(size_t x, size_t y, size_t z, T delegate(size_t, size_t, size_t) getValFunc)
	{
		T[][][] buff = new T[][][z];

		foreach(ref arr1; buff)
		{
			arr1 = new uint[][y];
			foreach(ref arr2; arr1)
				arr2 = new uint[x];
		}

		for(size_t i=0; i<x; i++)
			for(size_t j=0; j<y; j++)
				for(size_t k=0; k<z; k++)
				{
					if((i-x/2)*(i-x/2)/(cast(double)x*x/4)+(j-y/2)*(j-y/2)/(cast(double)y*y/4)+(k-z/2)*(k-z/2)/(cast(double)z*z/4) <= 1)
					{
						buff[i][j][k] = getValFunc(i,j,k);
					}
				}

		return buff;
	}
}