/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.ogg.ogg;

public
{
    import derelict.ogg.oggtypes;
    import derelict.ogg.oggfunctions;
}

private
{
    import derelict.util.loader;
    import derelict.util.system;

    static if(Derelict_OS_Windows)
        enum libNames = "ogg.dll, libogg.dll";
    else static if(Derelict_OS_Mac)
        enum libNames = "libogg.dylib, libogg.0.dylib";
    else static if(Derelict_OS_Posix)
        enum libNames = "libogg.so, libogg.so.0";
    else
        static assert(0, "Need to implement libogg libnames for this operating system.");
}

class DerelictOggLoader : SharedLibLoader
{

protected:
    override void loadSymbols()
    {
        bindFunc(cast(void**)&oggpack_writeinit, "oggpack_writeinit");
        bindFunc(cast(void**)&oggpack_writecheck, "oggpack_writecheck");
        bindFunc(cast(void**)&oggpack_writetrunc, "oggpack_writetrunc");
        bindFunc(cast(void**)&oggpack_writealign, "oggpack_writealign");
        bindFunc(cast(void**)&oggpack_writecopy, "oggpack_writecopy");
        bindFunc(cast(void**)&oggpack_reset, "oggpack_reset");
        bindFunc(cast(void**)&oggpack_writeclear, "oggpack_writeclear");
        bindFunc(cast(void**)&oggpack_readinit, "oggpack_readinit");
        bindFunc(cast(void**)&oggpack_write, "oggpack_write");
        bindFunc(cast(void**)&oggpack_look, "oggpack_look");
        bindFunc(cast(void**)&oggpack_look1, "oggpack_look1");
        bindFunc(cast(void**)&oggpack_adv, "oggpack_adv");
        bindFunc(cast(void**)&oggpack_adv1, "oggpack_adv1");
        bindFunc(cast(void**)&oggpack_read, "oggpack_read");
        bindFunc(cast(void**)&oggpack_read1, "oggpack_read1");
        bindFunc(cast(void**)&oggpack_bytes, "oggpack_bytes");
        bindFunc(cast(void**)&oggpack_bits, "oggpack_bits");
        bindFunc(cast(void**)&oggpack_get_buffer, "oggpack_get_buffer");

        bindFunc(cast(void**)&oggpackB_writeinit, "oggpackB_writeinit");
        bindFunc(cast(void**)&oggpackB_writecheck, "oggpackB_writecheck");
        bindFunc(cast(void**)&oggpackB_writetrunc, "oggpackB_writetrunc");
        bindFunc(cast(void**)&oggpackB_writealign, "oggpackB_writealign");
        bindFunc(cast(void**)&oggpackB_writecopy, "oggpackB_writecopy");
        bindFunc(cast(void**)&oggpackB_reset, "oggpackB_reset");
        bindFunc(cast(void**)&oggpackB_writeclear, "oggpackB_writeclear");
        bindFunc(cast(void**)&oggpackB_readinit, "oggpackB_readinit");
        bindFunc(cast(void**)&oggpackB_write, "oggpackB_write");
        bindFunc(cast(void**)&oggpackB_look, "oggpackB_look");
        bindFunc(cast(void**)&oggpackB_look1, "oggpackB_look1");
        bindFunc(cast(void**)&oggpackB_adv, "oggpackB_adv");
        bindFunc(cast(void**)&oggpackB_adv1, "oggpackB_adv1");
        bindFunc(cast(void**)&oggpackB_read, "oggpackB_read");
        bindFunc(cast(void**)&oggpackB_read1, "oggpackB_read1");
        bindFunc(cast(void**)&oggpackB_bytes, "oggpackB_bytes");
        bindFunc(cast(void**)&oggpackB_bits, "oggpackB_bits");
        bindFunc(cast(void**)&oggpackB_get_buffer, "oggpackB_get_buffer");

        bindFunc(cast(void**)&ogg_stream_packetin, "ogg_stream_packetin");
        bindFunc(cast(void**)&ogg_stream_iovecin, "ogg_stream_iovecin");
        bindFunc(cast(void**)&ogg_stream_pageout, "ogg_stream_pageout");
        bindFunc(cast(void**)&ogg_stream_pageout_fill, "ogg_stream_pageout_fill");
        bindFunc(cast(void**)&ogg_stream_flush, "ogg_stream_flush");
        bindFunc(cast(void**)&ogg_stream_flush_fill, "ogg_stream_flush_fill");

        bindFunc(cast(void**)&ogg_sync_init, "ogg_sync_init");
        bindFunc(cast(void**)&ogg_sync_clear, "ogg_sync_clear");
        bindFunc(cast(void**)&ogg_sync_reset, "ogg_sync_reset");
        bindFunc(cast(void**)&ogg_sync_destroy, "ogg_sync_destroy");
        bindFunc(cast(void**)&ogg_sync_check, "ogg_sync_check");

        bindFunc(cast(void**)&ogg_sync_buffer, "ogg_sync_buffer");
        bindFunc(cast(void**)&ogg_sync_wrote, "ogg_sync_wrote");
        bindFunc(cast(void**)&ogg_sync_pageseek, "ogg_sync_pageseek");
        bindFunc(cast(void**)&ogg_sync_pageout, "ogg_sync_pageout");
        bindFunc(cast(void**)&ogg_stream_pagein, "ogg_stream_pagein");
        bindFunc(cast(void**)&ogg_stream_packetout, "ogg_stream_packetout");
        bindFunc(cast(void**)&ogg_stream_packetpeek, "ogg_stream_packetpeek");

        bindFunc(cast(void**)&ogg_stream_init, "ogg_stream_init");
        bindFunc(cast(void**)&ogg_stream_clear, "ogg_stream_clear");
        bindFunc(cast(void**)&ogg_stream_reset, "ogg_stream_reset");
        bindFunc(cast(void**)&ogg_stream_reset_serialno, "ogg_stream_reset_serialno");
        bindFunc(cast(void**)&ogg_stream_destroy, "ogg_stream_destroy");
        bindFunc(cast(void**)&ogg_stream_check, "ogg_stream_check");
        bindFunc(cast(void**)&ogg_stream_eos, "ogg_stream_eos");

        bindFunc(cast(void**)&ogg_page_checksum_set, "ogg_page_checksum_set");
        bindFunc(cast(void**)&ogg_page_version, "ogg_page_version");
        bindFunc(cast(void**)&ogg_page_continued, "ogg_page_continued");
        bindFunc(cast(void**)&ogg_page_bos, "ogg_page_bos");
        bindFunc(cast(void**)&ogg_page_eos, "ogg_page_eos");
        bindFunc(cast(void**)&ogg_page_granulepos, "ogg_page_granulepos");
        bindFunc(cast(void**)&ogg_page_serialno, "ogg_page_serialno");
        bindFunc(cast(void**)&ogg_page_pageno, "ogg_page_pageno");
        bindFunc(cast(void**)&ogg_page_packets, "ogg_page_packets");
        bindFunc(cast(void**)&ogg_packet_clear, "ogg_packet_clear");
    }

    public
    {
        this()
        {
            super(libNames);
        }
    }
}

__gshared DerelictOggLoader DerelictOgg;

static this()
{
    DerelictOgg = new DerelictOggLoader();
}

static ~this()
{
    DerelictOgg.unload();
}