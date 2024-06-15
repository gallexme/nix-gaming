rec {
  base = {
    gettextSupport = true;
    fontconfigSupport = true;
    alsaSupport = true;
    openglSupport = true;
    vulkanSupport = true;
    tlsSupport = true;
    cupsSupport = true;
    dbusSupport = true;
    cairoSupport = true;
    cursesSupport = true;
    saneSupport = true;
    pulseaudioSupport = true;
    udevSupport = true;
    xineramaSupport = true;
    sdlSupport = true;
    mingwSupport = true;
    gtkSupport = true;
    gstreamerSupport = true;
    openalSupport = true;
    openclSupport = true;
    odbcSupport = true;
    netapiSupport = true;
    vaSupport = true;
    pcapSupport = true;
    v4lSupport = true;
    gphoto2Support = true;
    krb5Support = true;
    embedInstallers = true;
    x11Support = true;
    waylandSupport = true;
    usbSupport = true;
  };

  full =
    base
    // {
      gtkSupport = true;
      gstreamerSupport = true;
      openalSupport = true;
      openclSupport = true;
      odbcSupport = true;
      netapiSupport = true;
      vaSupport = true;
      pcapSupport = true;
      v4lSupport = true;
      gphoto2Support = true;
      embedInstallers = true;
    };
}
