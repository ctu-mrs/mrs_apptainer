// Minimal GLX probe: prints GL_VENDOR/RENDERER/VERSION and direct-rendering
// status. Equivalent to the interesting part of `glxinfo -B`, which is not
// installed in the container.
#include <GL/glx.h>
#include <GL/gl.h>
#include <X11/Xlib.h>
#include <stdio.h>

int main(void) {
  Display *dpy = XOpenDisplay(NULL);
  if (!dpy) { fprintf(stderr, "cannot open display\n"); return 1; }

  int attrs[] = { GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, None };
  XVisualInfo *vi = glXChooseVisual(dpy, DefaultScreen(dpy), attrs);
  if (!vi) { fprintf(stderr, "no suitable visual\n"); return 1; }

  GLXContext ctx = glXCreateContext(dpy, vi, NULL, True);
  if (!ctx) { fprintf(stderr, "cannot create context\n"); return 1; }

  XSetWindowAttributes swa;
  swa.colormap = XCreateColormap(dpy, RootWindow(dpy, vi->screen),
                                 vi->visual, AllocNone);
  Window win = XCreateWindow(dpy, RootWindow(dpy, vi->screen), 0, 0, 64, 64, 0,
                             vi->depth, InputOutput, vi->visual, CWColormap, &swa);
  if (!glXMakeCurrent(dpy, win, ctx)) {
    fprintf(stderr, "cannot make context current\n"); return 1;
  }

  printf("direct rendering: %s\n", glXIsDirect(dpy, ctx) ? "Yes" : "No");
  printf("GL_VENDOR       : %s\n", glGetString(GL_VENDOR));
  printf("GL_RENDERER     : %s\n", glGetString(GL_RENDERER));
  printf("GL_VERSION      : %s\n", glGetString(GL_VERSION));
  return 0;
}
