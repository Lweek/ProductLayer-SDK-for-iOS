//
//  PLYCategoryPickerViewController.h
//  PL
//
//  Created by Oliver Drobnik on 11/11/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "PLYTableViewController.h"

@class PLYCategoryPickerViewController;

@protocol PLYCategoryPickerViewControllerDelegate <NSObject>

@optional
- (void)categoryPicker:(PLYCategoryPickerViewController *)categoryPicker didSelectCategoryWithKey:(NSString *)key;

@end


@interface PLYCategoryPickerViewController : PLYTableViewController

@property (nonatomic, weak) id <PLYCategoryPickerViewControllerDelegate> delegate;

@property (nonatomic, copy) NSString *selectedCategoryKey;

@end
