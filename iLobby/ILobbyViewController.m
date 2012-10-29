//
//  ILobbyViewController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyViewController.h"
#import "ILobbyConfigurationController.h"
#import "ILobbyTrackViewCell.h"
#import "ILobbyTrack.h"

static NSString *SHOW_CONFIGURATION_SEGUE_ID = @"ShowConfiguration";


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
	self.lobbyModel = nil;
}


- (void)setLobbyModel:(ILobbyModel *)lobbyModel {
	ILobbyModel *oldModel = _lobbyModel;
	
	if ( oldModel ) {
		[oldModel removeObserver:self forKeyPath:@"tracks"];
		[oldModel removeObserver:self forKeyPath:@"currentTrack"];
	}

	_lobbyModel = lobbyModel;

	if ( lobbyModel ) {
		[lobbyModel addObserver:self forKeyPath:@"tracks" options:NSKeyValueObservingOptionNew context:nil];
		[lobbyModel addObserver:self forKeyPath:@"currentTrack" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ( [object isKindOfClass:[ILobbyModel class]] ) {
		if ( [keyPath isEqualToString:@"tracks"] ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				[self.collectionView reloadData];
			});
		}
		else if ( [keyPath isEqualToString:@"currentTrack"] ) {
			NSArray *tracks = self.lobbyModel.tracks;
			ILobbyTrack *oldTrack = change[ NSKeyValueChangeOldKey ];
			ILobbyTrack *currentTrack = change[ NSKeyValueChangeNewKey ];

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
	return self.lobbyModel.tracks.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyTrackViewCell *cell = (ILobbyTrackViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TrackCell" forIndexPath:indexPath];
	NSInteger item = indexPath.item;
	ILobbyTrack *track = self.lobbyModel.tracks[item];
	
	cell.label.text = track.label;
	cell.imageView.image = track.icon;
	cell.outlined = track == self.lobbyModel.currentTrack;

	return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
	
	NSInteger item = indexPath.item;
	[self.lobbyModel playTrackAtIndex:item];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.collectionView.allowsSelection = YES;
	self.collectionView.allowsMultipleSelection = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Prepare for the segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueID = [segue identifier];

    if ( [segueID isEqualToString:SHOW_CONFIGURATION_SEGUE_ID] ) {
        ILobbyConfigurationController *configurationController = [segue destinationViewController];
		configurationController.lobbyModel = self.lobbyModel;
    }
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}

@end
