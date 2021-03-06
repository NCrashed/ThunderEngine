//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Модуль, занимающийся отрисовкой на клиенте
/**
*	@file rendersys.d В модуле описаны все необходимое для отрисовки графики.
*	@todo Разделить модуль на несколько подсистем.
*/
module client.rendersys;

public
{
	import derelict.opengl3.gl3;
	import derelict.glfw3.glfw3;
	import derelict.freeimage.freeimage;
}

import util.log;
import util.common;
import util.resources.resmng;
import util.matrix;
import util.singleton;
import clmodel = client.model.model;

import util.resources.resmng;
import client.graphconf;
import client.camera;
import client.model.model;

import client.texture;
import client.scenemanager;
//import client.stdscenemanager;

import std.conv;
import std.string;
import std.array;
import std.stdio;
import std.exception;
import std.datetime;
import std.algorithm;
import std.path;

enum RENDER_LOG = "RenderLog.log";
enum SHADERS_GROUP = "General";
enum STD_SCENE_MANAGER = "client.stdscenemanager.StdSceneManager";

private extern(C) void glfw3ErrorCallback(int error, const(char)* description)
{
    writeLog(fromStringz(description), LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
}

/// Занимается отрисовкой сцены на экран
/**
*   @todo Нужно заставить SceneManager сортировать объекты по удалению от камеры
*/
class RenderSystem
{
    mixin Singleton!RenderSystem;

    this()
    {
        version(Windows)
        {
            DerelictGL3.load();
            DerelictGLFW3.load();
            DerelictFI.load();
        }
        version(linux)
        {
            DerelictGL3.load();
            DerelictGLFW3.load("./libglfw3.so");
            DerelictFI.load("./libfreeimage.so");      
        }

        createLog(RENDER_LOG);

        writeLog("Initing GLFW3...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        if ( !glfwInit() )
        {
            writeLog("Failed to init GLF3!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("Failed to init GLFW3!");
        }
        glfwSetErrorCallback(&glfw3ErrorCallback);

        // Вообще я был удивлен, что кастом можно добавить флаг nothrow к функции Оо
        writeLog("Initing FreeImage...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        FreeImage_SetOutputMessage(cast(FreeImage_OutputMessageFunction)&RenderSystem.FreeImageErrorHandler);
    }

    /// Инициализация системы отрисовки
    void initRenderSys(string windowTitle)
    {
        initWindow(windowTitle);
        initExtOpengl();
        initGl();
        loadStdShaders();

        // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
        mProjection = projection(deg2rad(45.0f), cast(float)mGraphicConfigs.screenY / cast(float)mGraphicConfigs.screenX, 0.1f, 100.0f); 

        if(!ARB_framebuffer_object)
        {
            writeLog("ARB_framebuffer_object extention wasn't found! Fatal error!",LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("ARB_framebuffer_object extention wasn't found! Fatal error!");
        }
    }
    
    /// Отрисовка сцены
    /**
    *   @par camera Камера, для которой будет отрисована сцена
    */
    void drawScene(Camera camera)
    {
        enforce(mScenemng !is null, "SceneManager not selected! Please load manager with RenderSystem.setSceneManager(string name)!");

        auto tuples = mScenemng.getToRender(camera);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        foreach(t; tuples)
        {
            auto mesh = t.mesh;
            auto node = t.node;
            // Итого у нас есть model, node, camera
            mModel = node.modelMatrix;
            mView = camera.getMatrix();

            loadModel(mesh);
			mesh.applyOptions();
			
            mMVP =  mProjection*(mView*mModel);

            vec3 lightPos = vec3(1,2,1);
            // Use our shader
            glUseProgram(programID);
            glUniformMatrix4fv(MatrixID, 1, GL_FALSE, mMVP.toOpenGL());
            glUniformMatrix4fv(ModelMtrxID, 1, GL_FALSE, mModel.toOpenGL());
            glUniformMatrix4fv(CameraMtrxID, 1, GL_FALSE, mView.toOpenGL());
            glUniformMatrix4fv(MVMtrxID, 1, GL_FALSE, (mModel*mView).toOpenGL());
            glUniform3f(LightPosID, lightPos.x, lightPos.y, lightPos.z);

            // Bind our texture in Texture Unit 0
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, mesh.texture);
			
            // Set our "myTextureSampler" sampler to user Texture Unit 0
            glUniform1i(TextureID, 0);

            // 1rst attribute buffer : vertices
            glEnableVertexAttribArray(0);
            glBindBuffer(GL_ARRAY_BUFFER, mVertexBuffer);
            glVertexAttribPointer(
                0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
                3,                  // size
                GL_FLOAT,           // type
                GL_FALSE,           // normalized?
                0,                  // stride
                null            // array buffer offset
            );

            glEnableVertexAttribArray(1);
            glBindBuffer(GL_ARRAY_BUFFER, mUvBuffer);
            glVertexAttribPointer(
                1,                                // attribute. No particular reason for 1, but must match the layout in the shader.
                2,                                // size
                GL_FLOAT,                         // type
                GL_FALSE,                         // normalized?
                0,                                // stride
                null                          // array buffer offset
            );

            // 3rd attribute buffer : normals
            glEnableVertexAttribArray(2);
            glBindBuffer(GL_ARRAY_BUFFER, mNormalBuffer);
            glVertexAttribPointer(
                2,                                // attribute
                3,                                // size
                GL_FLOAT,                         // type
                GL_FALSE,                         // normalized?
                0,                                // stride
                null                          // array buffer offset
            );

            // Index buffer
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mElementBuffer);
                             
            // Draw the triangles !
            glDrawElements(
                GL_TRIANGLES,          // mode
                cast(uint)mesh.indecies.length,  // count
                GL_UNSIGNED_INT,       // type
                null                   // element array buffer offset
            );

            glDisableVertexAttribArray(0);
            glDisableVertexAttribArray(1);
            glDisableVertexAttribArray(2);

            unloadModel();
        }
    }

    /// Сохраняет текущее отрендеренное изображение в файл
    void saveScreen2File(string name = "")
    {
    /*    if(name.length == 0)
            name = Clock.currTime().toISOString();

        glBindBuffer(GL_TEXTURE_2D, renderTexId2);
        glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
        GLint width, height;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &height);

        auto bitmap = FreeImage_Allocate(width, height, 32, 0xFF000000u, 0x00FF0000u, 0x0000FF00u);
        auto texture = new ubyte[4*width*height];
        char* pixels = cast(char*)FreeImage_GetBits(bitmap);

        glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture.ptr);
		
        for(int pix=0; pix<mGraphicConfigs.screenX*mGraphicConfigs.screenY; pix++)
        {
            pixels[pix*uint.sizeof+2] = (cast(char*)&texture[pix*uint.sizeof])[0];
            pixels[pix*uint.sizeof+1] = (cast(char*)&texture[pix*uint.sizeof])[1];
            pixels[pix*uint.sizeof+0] = (cast(char*)&texture[pix*uint.sizeof])[2];
            pixels[pix*uint.sizeof+3] = (cast(char*)&texture[pix*uint.sizeof])[3];
        }

        string basepath;
        try basepath = ResourceMng.getSingleton().getByName("Images").basePath;
        catch(Exception e)
        {
            writeLog("Failed to save texture to "~name~", because: "~e.msg);
            return;
        }

        FreeImage_Save(FIF_PNG, bitmap, toStringz(basepath~dirSeparator~name~".png"), 0);
        FreeImage_Unload(bitmap);*/
    }

    /// Получение текущих графических настроек
    @property const GraphConf graphicConfigs()
    {
        return mGraphicConfigs;
    }

    @property void graphicConfigs(GraphConf val)
    {
        mGraphicConfigs = val;

        mProjection = projection(deg2rad(45.0f), cast(float)mGraphicConfigs.screenY / cast(float)mGraphicConfigs.screenX, 0.1f, 100.0f); 
        glfwSetWindowSize(mWindow, val.screenX, val.screenY);
        glViewport(0,0,val.screenX, val.screenY);
    }

    /// Получение окна приложения
    @property GLFWwindow window()
    {
        return *mWindow;
    }

    /// Returns pointer to window
    /**
    *   Simplifies using glfwSwapBuffers and others glfw callback setting.
    */
    @property GLFWwindow* windowPtr()
    {
        return mWindow;
    }

    /// Получение времени с предыдущего кадра
    @property double timing()
    {
        return dt;
    }

    /// Установка нужного SceneManager
    void setSceneManager(string name)
    {
        mScenemng = cast(SceneManager)Object.factory(name);
        enforce(mScenemng !is null, "Failed to load "~name~" scene manager!");
    }

    ~this()
    {
        glDeleteProgram(programID);
        glDeleteVertexArrays(1, &mVertexArrayID);      

        glDeleteBuffers(1, &mVertexBuffer);
        glDeleteBuffers(1, &mUvBuffer);
        glDeleteBuffers(1, &mNormalBuffer); 
    }

    /// Замер скорости отрисовки
    /**
    *   @return Время от предыдущего запуска функции.
    */
    double renderTiming()
    {
        t = glfwGetTime();
        dt = t - t_old;
        t_old = t;
        return dt;
    }

    /// Условие продолжения выполнения приложения
    /**
    *   @return false - выходим из приложения
    */
    bool shouldContinue()
    {
        return (glfwWindowShouldClose(mWindow) == 0);
    }

    /// Получение текущего сцен менджера
    @property SceneManager sceneManager()
    {
        return mScenemng;
    }

private:

    /// После загрузки настройки графики хранятся здесь
    GraphConf mGraphicConfigs;

    /// Окно приложения
    GLFWwindow* mWindow;
    /// Переменные для замера скорости отрисовки
    double t = 0., t_old = 0., dt = 0.;

    /// Матрицы, которые передаются в шейдер
    Matrix!4 mView;
    Matrix!4 mProjection;
    Matrix!4 mModel;
    Matrix!4 mMVP;

    /// Временные переменные для шейдеров
    /// Этим должен заниматься менджер шейдеров
    GLuint programID; //temp
    GLuint MatrixID;
    GLuint ModelMtrxID;
    GLuint CameraMtrxID;
    GLuint TextureID;
    GLuint MVMtrxID;
    GLuint LightPosID;

    /// Буферы
    GLuint mVertexArrayID;
    GLuint mVertexBuffer;
    GLuint mUvBuffer;
    GLuint mNormalBuffer;
    GLuint mElementBuffer;

    SceneManager mScenemng;
private:

    /// Обработчик ошибок FreeImage
    /**
    *   @par fif Формат или плагин, который ответственен за ошибку
    *   @par message Сообщение об ошибке
    */
    extern(C) static void FreeImageErrorHandler(FREE_IMAGE_FORMAT fif, const char *msg) 
    {
        if(fif != FIF_UNKNOWN)
        {
            writeLog(fromStringz(FreeImage_GetFormatFromFIF(fif))~" Format: "~fromStringz(msg), LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
        } else
        {
            writeLog("Unknown Format: "~fromStringz(msg), LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
        }
    }


    /// Инициализация opengl
    /**
    *   @todo Большую часть перенести в материалы
    */
    void initGl()
    {
        writeLog("Initing opengl...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        glGenVertexArrays(1, &mVertexArrayID);
        glBindVertexArray(mVertexArrayID);

        // Enable depth test
        glEnable(GL_DEPTH_TEST);
        // Accept fragment if it closer to the camera than the former one
        glDepthFunc(GL_LESS);
        glEnable(GL_CULL_FACE);

        // Enable blending
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glClearColor(0.0f, 0.0f, 0.3f, 0.0f);

        glGenBuffers(1, &mVertexBuffer);
        glGenBuffers(1, &mUvBuffer);
        glGenBuffers(1, &mNormalBuffer);
        glGenBuffers(1, &mElementBuffer);
    }

    /// Загрузка стандартных шейдеров
    /**
    *   @todo Работу с шейдерами перенести в менеджер с шейдерами.
    */
    void loadStdShaders()
    {
        writeLog("Initing shaders...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
        // Create and compile our GLSL program from the shaders
        programID = LoadShaders( "../Media/Shaders/VertexShader.glsl", "../Media/Shaders/FragmentShader.glsl" );

        MatrixID = glGetUniformLocation(programID, "MVP");
        ModelMtrxID = glGetUniformLocation(programID, "M");
        CameraMtrxID = glGetUniformLocation(programID, "V");
        MVMtrxID = glGetUniformLocation(programID, "MV");
        LightPosID = glGetUniformLocation(programID, "LightPosition_worldspace");

        // Get a handle for our "myTextureSampler" uniform
        TextureID  = glGetUniformLocation(programID, "myTextureSampler");
    }

    /// Загружаем продвинутый OpenGL
    void initExtOpengl()
    {
        GLVersion glver = DerelictGL3.reload();
        writeLog("OpenGL version: "~to!string(DerelictGL3.loadedVersion), LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);

        if(DerelictGL3.loadedVersion < GLVersion.GL30)
        {
            writeLog("OpenGL version too low!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("OpenGL version too low!");
        }
        if(!ARB_sync)
        {
            writeLog("No ARB_sync extension detected!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            throw new Exception("No ARB_sync extension detected!");
        }
    }

    /// Создание окна приложения
    /**
    *   @par tittle Заголовок окна
    */
    void initWindow(string tittle)
    {
        writeLog("Initing app window...", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);

        // Получаем графические настройки
        GraphConf grConf;
        if (!isConfExists(GRAPH_CONF))
            writeConf(GRAPH_CONF, grConf);
        else
            grConf = readConf!GraphConf(GRAPH_CONF);

        // Загружаем окно
        //glfwWindowHint(GLFW_DEPTH_BITS, grConf.depthBits); TODO: Fix depthBits crashed
        glfwWindowHint(GLFW_FSAA_SAMPLES, 4);

        GLFWmonitor* mMonitor = null;
        if(!grConf.windowed) mMonitor = glfwGetPrimaryMonitor();
		
        mWindow = glfwCreateWindow( grConf.screenX, grConf.screenY, toStringz(tittle), mMonitor, null );
        if ( mWindow is null)
        {
            writeLog("Failed to create window!", LOG_ERROR_LEVEL.FATAL, RENDER_LOG);
            glfwTerminate();
            throw new Exception("Failed to create window!");
        }
        glfwMakeContextCurrent(mWindow);

        glfwSetInputMode( mWindow, GLFW_STICKY_KEYS, GL_TRUE );
        glfwSetTime( 0.0 );

        // Включение вертикальной синхронизации
        if (grConf.vertSync) setVsync(true);

        mGraphicConfigs = grConf;
    }

    /// Вулючение и выключение вертикальной синхронизации
    void setVsync(bool flag)
    {
        glfwSwapInterval(flag ? 1 : 0);
    }

    void loadModel(Mesh mesh)
    {
        //static bool test = true;
        //if(!test) return;
        //test = false;

        // Generate 1 buffer, put the resulting identifier in vertexbuffer
        // The following commands will talk about our 'vertexbuffer' buffer
        glBindBuffer(GL_ARRAY_BUFFER, mVertexBuffer);
        // Give our vertices to OpenGL.
        glBufferData(GL_ARRAY_BUFFER, mesh.vertecies.length*float.sizeof, mesh.vertecies.ptr, GL_STATIC_DRAW);


        glBindBuffer(GL_ARRAY_BUFFER, mUvBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.uvs.length*float.sizeof, mesh.uvs.ptr, GL_STATIC_DRAW);


        glBindBuffer(GL_ARRAY_BUFFER, mNormalBuffer);
        glBufferData(GL_ARRAY_BUFFER, mesh.normals.length*float.sizeof, mesh.normals.ptr, GL_STATIC_DRAW);


        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mElementBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indecies.length*uint.sizeof, mesh.indecies.ptr, GL_STATIC_DRAW);
    }

    void unloadModel()
    {

    }

}



/// Загрузка основных шейдеров
private GLuint LoadShaders(string vertex_file_path, string fragment_file_path)
{
    // Create the shaders
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
 	auto rmng = ResourceMng.getSingleton();

    // Read the Vertex Shader code from the file
    string VertexShaderCode;
    string fullname;
    auto VertexShaderFile = rmng.loadFile(vertex_file_path, SHADERS_GROUP, fullname);
    while(!VertexShaderFile.eof())
    {
    	string line = VertexShaderFile.readLine().idup;
    	VertexShaderCode ~= "\n" ~ line;
    }


    string FragmentShaderCode;
    auto FragmentShaderFile = rmng.loadFile(fragment_file_path, SHADERS_GROUP, fullname);
    while(!FragmentShaderFile.eof())
    {
    	string line = FragmentShaderFile.readLine().idup;
    	FragmentShaderCode ~= "\n" ~ line;
    }
    FragmentShaderFile.close();

    GLint Result = GL_FALSE;
    int InfoLogLength;
 
    // Compile Vertex Shader
    writeLog("Compiling shader : "~vertex_file_path, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    auto VertexSourcePointer = toStringz(VertexShaderCode);
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , null);
    glCompileShader(VertexShaderID);
 
    // Check Vertex Shader
    glGetShaderiv(VertexShaderID, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    if(InfoLogLength > 0)
    {
        auto VertexShaderErrorMessage = new char[InfoLogLength];
        glGetShaderInfoLog(VertexShaderID, InfoLogLength, null, &VertexShaderErrorMessage[0]);
        writeLog(VertexShaderErrorMessage.idup, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    } else
    {
        writeLog("No output from vertex shader compilation.", LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
    }

    // Compile Fragment Shader
    writeLog("Compiling shader : "~fragment_file_path, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    auto FragmentSourcePointer = toStringz(FragmentShaderCode);
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , null);
    glCompileShader(FragmentShaderID);
 
    // Check Fragment Shader
    glGetShaderiv(FragmentShaderID, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    if(InfoLogLength > 0)
    {
        auto FragmentShaderErrorMessage = new char[InfoLogLength];
        glGetShaderInfoLog(FragmentShaderID, InfoLogLength, null, &FragmentShaderErrorMessage[0]);
        writeLog(FragmentShaderErrorMessage.idup, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    } else
    {
        writeLog("No output from fragment shader compilation.", LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
    }
 
    // Link the program
    writeLog("Linking program", LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    GLuint ProgramID = glCreateProgram();
    glAttachShader(ProgramID, VertexShaderID);
    glAttachShader(ProgramID, FragmentShaderID);
    glLinkProgram(ProgramID);
 
    // Check the program
    glGetProgramiv(ProgramID, GL_LINK_STATUS, &Result);
    glGetProgramiv(ProgramID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    if(InfoLogLength > 0)
    {
        auto ProgramErrorMessage = new char[InfoLogLength];
        glGetProgramInfoLog(ProgramID, InfoLogLength, null, &ProgramErrorMessage[0]);
        writeLog(ProgramErrorMessage.idup, LOG_ERROR_LEVEL.NOTICE, RENDER_LOG);
    } else
    {
        writeLog("No output from shader linking.", LOG_ERROR_LEVEL.WARNING, RENDER_LOG);
    }

    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
 
    return ProgramID;
}