//
//  BCNAppDelegate.m
//  CloudPhotos
//
//  Created by Hermes on 24/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "BCNAppDelegate.h"
#import "BCNCoreDataManager.h"
#import "BCNTableViewController.h"

@implementation BCNAppDelegate

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BCNCoreDataManagerStoreDidChangeNotification object:[BCNCoreDataManager sharedManager]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeDidChangeNotification:) name:BCNCoreDataManagerStoreDidChangeNotification object:[BCNCoreDataManager sharedManager]];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self loadRootViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[BCNCoreDataManager sharedManager] saveContext];
}

#pragma mark Private

- (void)loadRootViewController
{
    UIViewController *viewController = [BCNTableViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

#pragma mark Notifications

- (void)storeDidChangeNotification:(NSNotification*)notification
{
    if (self.window.rootViewController)
    {
        [self loadRootViewController];
    }
}

@end
