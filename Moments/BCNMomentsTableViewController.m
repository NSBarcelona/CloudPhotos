//
//  BCNMomentsTableViewController.m
//  Moments
//
//  Created by Hermes on 24/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "BCNMomentsTableViewController.h"
#import "BCNMoment.h"
#import "BCNCoreDataManager.h"

static NSString *BCNMomentsTableViewControllerCellIdentifier = @"Cell";

@interface BCNMomentsTableViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation BCNMomentsTableViewController {
    NSArray *_moments;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Moments", @"");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonItem:)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:BCNMomentsTableViewControllerCellIdentifier];
    
    {
        BCNCoreDataManager *manager = [BCNCoreDataManager sharedManager];
        _moments = [manager fetchMoments];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeWillChangeNotification:) name:BCNCoreDataManagerStoreWillChangeNotification object:manager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChangeNotification:) name:BCNCoreDataManagerObjectsDidChangeNotification object:manager];
    }
}

- (void)dealloc
{
    BCNCoreDataManager *manager = [BCNCoreDataManager sharedManager];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BCNCoreDataManagerStoreWillChangeNotification object:manager];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BCNCoreDataManagerObjectsDidChangeNotification object:manager];
}

#pragma mark Actions

- (void)addBarButtonItem:(UIBarButtonItem*)barButtonItem
{
    UIImagePickerControllerSourceType sourceType = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentImagePickerControllerWithType:sourceType];
}

#pragma mark UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _moments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BCNMomentsTableViewControllerCellIdentifier forIndexPath:indexPath];
    BCNMoment *moment = _moments[indexPath.row];
    cell.imageView.image = moment.image;
    
    NSDateFormatter *formatter = [self relativeDateFormatter];
    cell.textLabel.text = [formatter stringFromDate:moment.date];
    return cell;
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[BCNCoreDataManager sharedManager] insertMomentWithImage:image];
}

#pragma mark Notifications

- (void)storeWillChangeNotification:(NSNotification*)notification
{
    // Disable interaction with context and stop listening to its notifications
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BCNCoreDataManagerObjectsDidChangeNotification object:[BCNCoreDataManager sharedManager]];
}

- (void)objectsDidChangeNotification:(NSNotification*)notification
{
    _moments = [[BCNCoreDataManager sharedManager] fetchMoments];
    [self.tableView reloadData];
}

#pragma mark Utils

- (void)presentImagePickerControllerWithType:(UIImagePickerControllerSourceType)type
{
    UIImagePickerController *controller = [UIImagePickerController new];
    controller.delegate = self;
    controller.sourceType = type;
    [self presentViewController:controller animated:YES completion:nil];
}

- (NSDateFormatter*)relativeDateFormatter
{
    static NSDateFormatter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [NSDateFormatter new];
        instance.dateStyle = kCFDateFormatterShortStyle;
        instance.timeStyle = NSDateFormatterLongStyle;
        instance.doesRelativeDateFormatting = YES;
        instance.locale = [NSLocale currentLocale];
    });
    return instance;
}

@end
