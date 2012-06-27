C4MRequestManager
=================

Sample project
--------------

Sample project available on SVN at : ''svn/projects/C4MRequestManagerSample''

Usage
-----

Please refer to the C4MiOS_apiDemo project for implementation example.


Change Logs
-----------

### v1.4

Merges C4MRequestManager with its subclass C4MRequestManager_Reachability.\\
No instance of RKReachabilityObserver is create, you have to create one (in your application delegate).
The purpose is to be able to use RKReachabilityObserver with the C4MRequestManager and ImageManager at the same time.

### v1.3

Adds subclass C4MRequestManager_Reachability, that uses the RKReachabilityObserver class.\\
If there is no network, the C4MRequestManager_Reachability will not even send URLConnections.\\
If this class is used, you should not add another instance of RKReachabilityObserver in your project.

Beware that the RKReachabilityObserver will only be created once you call the sharedInstance of C4MRequestManager_Reachability.

### v1.2

Adds a timeout timer that is restarted each time data is received.\\
Default timeOut interval of C4MRequestGroup should be changed to 5 seconds or less.\\
{{:dev:iphone:c4mrequestmanager_1_2.zip|}}