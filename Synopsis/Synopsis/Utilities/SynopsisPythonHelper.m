//
//  SynopsisPythonHelper.m
//  Synopsis-Framework
//
//  Created by vade on 10/17/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisPythonHelper.h"
#import <Python/Python.h>

@interface SynopsisPythonHelper ()
@property (readwrite, strong) dispatch_queue_t pythonQueue;
@end

@implementation SynopsisPythonHelper

+ (instancetype) sharedHelper
{
    static SynopsisPythonHelper* sharedHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedHelper = [[SynopsisPythonHelper alloc] init];
    });
    
    return sharedHelper;
}

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        if (!Py_IsInitialized())
        {
            Py_SetProgramName("/usr/bin/python");
            // 0 - No Signal handlers installed
            Py_InitializeEx(0);
        }
        
        self.pythonQueue = dispatch_queue_create("pythonQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void) dealloc
{
    Py_Finalize();
}

- (BOOL) invokeScript:(NSURL*)scriptURL withArguments:(NSArray<NSString*>*)arguments
{
    __block BOOL result = NO;
    
    dispatch_sync(self.pythonQueue, ^{
        NSString* scriptPath = scriptURL.path;
        
        int argc = arguments.count + 1;
        
        char * argv[argc];
        
        // pass in program name as argv 0
        argv[0] = [[[scriptURL lastPathComponent] stringByAppendingPathExtension:[scriptURL pathExtension]] UTF8String];
        
        for(int i = 0; i < arguments.count; i++)
        {
            argv[i + 1] = [arguments[i] UTF8String];
        }
        
        PySys_SetArgv(argc, argv);
        
        // 1 - Close file before returning
        FILE *mainFile = fopen([scriptPath UTF8String], "r");
        result = PyRun_SimpleFileEx(mainFile, (char *)[[scriptPath lastPathComponent]UTF8String], 1);
    });
    
    if(result == 0)
    {
        // correct exit
        return TRUE;
    }
    else
        return FALSE;

}

@end
