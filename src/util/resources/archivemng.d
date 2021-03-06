//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Менеджер подключенных архивов
/**
*	@file archivemng.d Менеджер, который следит за подключенными типами архивов. Каждый тип архива создает и
*	регистрирует фабрику в менеджере для автоматизированного создания данного типа архивов.
*/
module util.resources.archivemng;

public import util.resources.archive;
import util.singleton;
import util.log;

/// Класс регистрирующий типы архивов
/**
*	Через него возможно создание и распознование архивов,
*	подключенных к системе.
*/
class ArchiveMng
{
	mixin Singleton!ArchiveMng;

	this()
	{
		mFabrics = new ArchiveFabric[0];
	}

	/// Добавление нового типа архива
	bool addArchiveType(ArchiveFabric fabr)
	{
		if (isRegistered(fabr.getType()))
		{
			writeLog("Detected simmilar archive fabrics! TypeId: "~fabr.getType(), LOG_ERROR_LEVEL.WARNING);
			return false;
		}
		
		mFabrics ~= fabr;
		return true;
	}

	/// Создание архива по его идентификатору
	Archive createArchive(string type)
	{
		if(!isRegistered(type))
		{
			writeLog("Tried to create not registered archive type: "~type, LOG_ERROR_LEVEL.FATAL);
			throw new Exception("Tried to create not registered archive type: "~type);
		}
		return mLastFinded.createInstance();
	}

	/// Проверка на наличие типа архива
	bool isRegistered(string type)
	{
		foreach(f; mFabrics)
			if(f.getType() == type)
			{
				mLastFinded = f;
				return true;
			}
		return false;
	}
private:
	ArchiveFabric[] mFabrics;
	/// Сохранение последней найденной фабрики
	ArchiveFabric	mLastFinded;
}
