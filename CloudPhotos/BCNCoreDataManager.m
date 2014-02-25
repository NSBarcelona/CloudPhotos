//
//  BCNCoreDataManager.m
//  CloudPhotos
//
//  Created by Hermes on 24/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "BCNCoreDataManager.h"
#import "BCNPhoto.h"

NSString *const BCNCoreDataManagerStoreWillChangeNotification = @"BCNCoreDataManagerStoreWillChange";
NSString *const BCNCoreDataManagerStoreDidChangeNotification = @"BCNCoreDataManagerStoreDidChange";
NSString *const BCNCoreDataManagerObjectsDidChangeNotification = @"BCNCoreDataManagerObjectsDidChange";

@interface BCNCoreDataManager()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation BCNCoreDataManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (instancetype)sharedManager
{
    static BCNCoreDataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BCNCoreDataManager new];
    });
    return instance;
}

#pragma mark Core Data stack

- (id)init
{
    self = [super init];
    if (self)
    {
        {
            NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CloudPhotos" withExtension:@"momd"];
            _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        }
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        {
            NSURL *documentsURL = [BCNCoreDataManager documentsDirectory];
            NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"CloudPhotos.sqlite"];
            
            NSError *error = nil;
            _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
            
            NSDictionary *options = @{ NSPersistentStoreUbiquitousContentNameKey : @"CloudPhotos" };
            
            if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:storeURL
                                                                 options:options
                                                                   error:&error])
            {
                NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                abort();
            }
            [notificationCenter addObserver:self selector:@selector(storesWillChange:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:_persistentStoreCoordinator];
            [notificationCenter addObserver:self selector:@selector(storesDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:_persistentStoreCoordinator];
            [notificationCenter addObserver:self selector:@selector(persistentStoreDidImportUbiquitousContentChanges:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:_persistentStoreCoordinator];
        }
        {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
            [notificationCenter addObserver:self selector:@selector(objectsDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:_persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:_persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:_persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext];
}

- (void)saveContext
{
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark Notifications

- (void)persistentStoreDidImportUbiquitousContentChanges:(NSNotification*)notification
{
    [_managedObjectContext performBlockAndWait:^{
        [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)objectsDidChangeNotification:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BCNCoreDataManagerObjectsDidChangeNotification object:self userInfo:nil];
}

- (void)storesWillChange:(NSNotification *)notification
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BCNCoreDataManagerStoreWillChangeNotification object:self];
    });
    [_managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        if ([_managedObjectContext hasChanges])
        {
            [_managedObjectContext save:&error];
        }
        [_managedObjectContext reset];
    }];
}

- (void)storesDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BCNCoreDataManagerStoreDidChangeNotification object:self];
    });
}

#pragma mark Photos

- (NSArray*)fetchPhotos
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date)) ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSError *error = nil;
    NSArray *objects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(objects, @"Fetch %@ failed with error %@", fetchRequest, error.localizedDescription);
    return objects;
}

- (void)insertPhotoWithImage:(UIImage*)image
{
    BCNPhoto *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:_managedObjectContext];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    photo.imageData = imageData;
    photo.date = [NSDate date];
    [self saveContext];
}

#pragma mark Utils

+ (NSURL *)documentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
