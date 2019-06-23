searchNodes=[{"ref":"Sample.Application.html","title":"Sample.Application","type":"module","doc":""},{"ref":"Sample.Application.html#start/2","title":"Sample.Application.start/2","type":"function","doc":"Called when an application is started. This function is called when an application is started using Application.start/2 (and functions on top of that, such as Application.ensure_started/2). This function should start the top-level process of the application (which should be the top supervisor of the application&#39;s supervision tree if the application follows the OTP design principles around supervision). start_type defines how the application is started: :normal - used if the startup is a normal startup or if the application is distributed and is started on the current node because of a failover from another node and the application specification key :start_phases is :undefined. {:takeover, node} - used if the application is distributed and is started on the current node because of a failover on the node node. {:failover, node} - used if the application is distributed and is started on the current node because of a failover on node node, and the application specification key :start_phases is not :undefined. start_args are the arguments passed to the application in the :mod specification key (e.g., mod: {MyApp, [:my_args]}). This function should either return {:ok, pid} or {:ok, pid, state} if startup is successful. pid should be the PID of the top supervisor. state can be an arbitrary term, and if omitted will default to []; if the application is later stopped, state is passed to the stop/1 callback (see the documentation for the c:stop/1 callback for more information). use Application provides no default implementation for the start/2 callback. Callback implementation for Application.start/2."},{"ref":"Sample.Application.html#start_cowboy/0","title":"Sample.Application.start_cowboy/0","type":"function","doc":""},{"ref":"Sample.Index.html","title":"Sample.Index","type":"module","doc":""},{"ref":"Sample.Index.html#chat/1","title":"Sample.Index.chat/1","type":"function","doc":""},{"ref":"Sample.Index.html#event/1","title":"Sample.Index.event/1","type":"function","doc":""},{"ref":"Sample.Login.html","title":"Sample.Login","type":"module","doc":""},{"ref":"Sample.Login.html#event/1","title":"Sample.Login.event/1","type":"function","doc":""},{"ref":"Sample.Routes.html","title":"Sample.Routes","type":"module","doc":""},{"ref":"Sample.Routes.html#finish/2","title":"Sample.Routes.finish/2","type":"function","doc":""},{"ref":"Sample.Routes.html#init/2","title":"Sample.Routes.init/2","type":"function","doc":""}]