//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/**
*	@file codec.d Описание интерфейса для кодирования/декодирования данных.
*	Используется для подключения различных форматов ресурсов к движку, кодирования
*	данных и пр. Каждая реализация кодека регистрирует себя в менджере, через который
*	пользователи могут получить доступ к кодекам.
*/
module util.codec;

public import std.stream;

/// Описание интерфейса для кодирования/декодирования данных.
/**
*	Используется для подключения различных форматов ресурсов к движку, кодирования
*	данных и пр. Каждая реализация кодека регистрирует себя в менджере, через который
*	пользователи могут получить доступ к кодекам.
*/
interface Codec
{
public:
	/// Получение уникального идентификатора кодека
	@property string type() const;

	/// Стандарт потока данных, который обеспечивает кодек
	/**
	*	Т.к. кодек возвращает поток данных, то нужно знать формат этого потока.
	*	Возвращаемая строка является именем стандарта, например "model", "image" и т.д.
	*	Стандарты описываются обычно в файлах с ресурсами, которые и пользуют кодеки.
	*/
	@property string standart() const;

	/// Декодирование данных 
	Stream decode(Stream data);

	/// Кодирование исходных данных
	Stream code(Stream data);
private:

}