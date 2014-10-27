//
//  ILobbyViewController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyViewController.h"
#import "ILobbyTrackViewCell.h"
#import "ILobbyPresentationGroupsTableController.h"
#import "DiTour-Swift.h"


static NSString *SEGUE_SHOW_CONFIGURATION_ID = @"MainToGroups";


@interface ILobbyViewController ()

@end


@implementation ILobbyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)dealloc {
	self.ditourModel = nil;
}


- (void)setDitourModel:(DitourModel *)ditourModel {
	DitourModel *oldModel = _ditourModel;
	
	if ( oldModel ) {
		[oldModel removeObserver:self forKeyPath:@"tracks"];
		[oldModel removeObserver:self forKeyPath:@"currentTrack"];
	}

	_ditourModel = ditourModel;

	if ( ditourModel ) {
		[ditourModel addObserver:self forKeyPath:@"tracks" options:NSKeyValueObservingOptionNew context:nil];
		[ditourModel addObserver:self forKeyPath:@"currentTrack" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	}
}


- (IBAction)reloadPresentation:(id)sender {
	[self.ditourModel reloadPresentation];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ( [object isKindOfClass:[DitourModel class]] ) {
		if ( [keyPath isEqualToString:@"tracks"] ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				[self.collectionView reloadData];
			});
		}
		else if ( [keyPath isEqualToString:@"currentTrack"] ) {
			NSArray *tracks = self.ditourModel.tracks;
			Track *oldTrack = change[ NSKeyValueChangeOldKey ];
			Track *currentTrack = change[ NSKeyValueChangeNewKey ];

			if ( tracks && oldTrack != currentTrack ) {
				NSMutableArray *paths = [NSMutableArray new];
				if ( oldTrack && [tracks containsObject:oldTrack] ) {	// verifies that oldTrack is still relevant (e.g. after presentation download)
					NSUInteger item = [tracks indexOfObjectIdenticalTo:oldTrack];
					if ( item != NSNotFound ) {
						[paths addObject:[NSIndexPath indexPathForItem:item inSection:0]];
					}
				}
				if ( currentTrack ) {
					NSUInteger item = [tracks indexOfObjectIdenticalTo:currentTrack];
					if ( item != NSNotFound ) {
						[paths addObject:[NSIndexPath indexPathForItem:item inSection:0]];
					}
				}
				dispatch_async( dispatch_get_main_queue(), ^{
					[self.collectionView reloadItemsAtIndexPaths:paths];
				});
			}
		}
	}
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.ditourModel.tracks.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyTrackViewCell *cell = (ILobbyTrackViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TrackCell" forIndexPath:indexPath];
	NSInteger item = indexPath.item;
	Track *track = self.ditourModel.tracks[item];
	
	cell.label.text = track.label;
	cell.imageView.image = track.icon;
	cell.outlined = track == self.ditourModel.currentTrack;

	return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
	
	NSInteger item = indexPath.item;
	[self.ditourModel playTrackAtIndex:item];
}


- (void)viewDidLoad {
    [super viewDidLoad];

	// Do any additional setup after loading the view.
	self.collectionView.allowsSelection = YES;
	self.collectionView.allowsMultipleSelection = NO;

	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Prepare for the segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueID = [segue identifier];

    if ( [segueID isEqualToString:SEGUE_SHOW_CONFIGURATION_ID] ) {
		ILobbyPresentationGroupsTableController *configController = segue.destinationViewController;
		configController.ditourModel = self.ditourModel;
    }
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}

@end
