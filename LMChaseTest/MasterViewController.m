//
//  MasterViewController.m
//  LMChaseTest
//
//  Created by laxman raju on 8/31/15.
//  Copyright (c) 2015 laxman raju. All rights reserved.
//

#define initialMusicSearchURL @"https://itunes.apple.com/search?term=tom+waits"
#import "MasterViewController.h"
#import "DetailViewController.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

@synthesize searchTextLabel = _searchTextLabel;


- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //show activity indication with spinner
    [self.spinner startAnimating];
    /*create the server call in another thread to keep main thread responsive to UI*/
    dispatch_queue_t other_Q = dispatch_queue_create("Q", NULL);
    dispatch_async(other_Q, ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:initialMusicSearchURL]];
        [self performSelector:@selector(fetchedData:) withObject:data];
    });
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

/*
 parse the json data
 clear the objects array
 fill the objects array with new data
 
 get the main thread to do the ui chnges (updating table view)
 */
- (void)fetchedData:(NSData *)responseData
{
    NSError *error = nil;
    if (responseData) {
        NSDictionary *jsonDataDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        
        [self.objects removeAllObjects];
        self.objects = [NSMutableArray arrayWithArray:[jsonDataDict objectForKey:@"results"]];
       
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.spinner stopAnimating];
        });
        
    }
}

/*
 search button action
 */

- (IBAction)searchAction:(UIButton *)sender
{
    [self.spinner startAnimating];
    if (_searchTextLabel.text) {
        /* create a url string by replacing spaces with + */
        NSString *urlString = [NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@",[_searchTextLabel.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
        
        dispatch_queue_t other_Q = dispatch_queue_create("Q", NULL);
        dispatch_async(other_Q, ^{
                           NSURL *url = [NSURL URLWithString:urlString];
                           NSData *jsonResults = [NSData dataWithContentsOfURL:url];
                           [self performSelector:@selector(fetchedData:) withObject:jsonResults];
        });
       
    }
    // to dismiss the keyboard
    [self.view endEditing:YES];
}

#pragma mark - Segues
/*Show the lyrics in detailed view */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            
            /*Creating the url string*/
            NSDictionary *itemDict = [NSDictionary dictionaryWithDictionary:[self.objects objectAtIndex:indexPath.row]];
            
            NSString *artistName = [NSString stringWithFormat:@"%@", [[itemDict objectForKey:@"artistName"] stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
            
            NSString *songName = [NSString stringWithFormat:@"%@", [[itemDict objectForKey:@"trackName"] stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
            
            NSString *urlString  = [NSString stringWithFormat:@"http://lyrics.wikia.com/api.php?func=getSong&artist=%@&song=%@&fmt=json", artistName, songName];
            
        
            
            DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
            [controller.spinner startAnimating];
            
            dispatch_queue_t other_Q = dispatch_queue_create("Q", NULL);
            
            dispatch_async(other_Q, ^{
                /*Have no time to write  a costom parser for the response data.. so displaying it directly*/
                NSURL *url = [NSURL URLWithString:urlString];
                NSString *dataString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
                /*getiin mainq for ui changes*/
                dispatch_async(dispatch_get_main_queue(), ^{
                    controller.lyricsView.text = dataString;
                    [controller.spinner stopAnimating];
                });
               
                
            });

            
            
            controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            controller.navigationItem.leftItemsSupplementBackButton = YES;
        }
      
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    
    NSDictionary *itemDict = [NSDictionary dictionaryWithDictionary:[self.objects objectAtIndex:indexPath.row]];
   
    cell.textLabel.text = [itemDict objectForKey:@"trackName"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@-%@",[itemDict objectForKey:@"artistName"], [itemDict objectForKey:@"collectionName"]];
    
    NSURL *imageURL = [NSURL URLWithString:[itemDict objectForKey:@"artworkUrl30"]];
    NSData *imgData = [NSData dataWithContentsOfURL:imageURL];
    cell.imageView.frame = CGRectMake(0, 0, 80, 70);
    cell.imageView.image = [UIImage imageWithData:imgData];

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end
