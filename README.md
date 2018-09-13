# DXGICapture2NamedPipe >>> NamedPipe2AutoIT 
DXGICaptureSample shows how to enumerate DXGI outputs and perform fast, non-GDI screen capturing.
More info at the original authors blog post:
http://ps.pavelgurenko.com/2013/12/dxgi-outputs-enumeration-and-fast.html

i added a named pipe connection from c++ to export the pixels.
in the autoit folder is a receiver that expects a running c++ binary and stores the pixels in a autoit array for further analyses.

with this example it is possible to fetch the framebuffer of a gpu rendered image multiple times a second and analyse it with the autoit programming language.
