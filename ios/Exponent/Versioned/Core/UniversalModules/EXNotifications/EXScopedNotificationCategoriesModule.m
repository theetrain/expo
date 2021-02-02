// Copyright 2018-present 650 Industries. All rights reserved.

#import "EXScopedNotificationCategoriesModule.h"
#import "EXScopedNotificationCategoryMigrator.h"
#import "EXScopedNotificationsUtils.h"

@interface EXScopedNotificationCategoriesModule ()

@property (nonatomic, strong) NSString *experienceId;

@end

@implementation EXScopedNotificationCategoriesModule

- (instancetype)initWithExperienceId:(NSString *)experienceId
                 andConstantsBinding:(EXConstantsBinding *)constantsBinding
{
  if (self = [super init]) {
    _experienceId = experienceId;
  }
  return self;
}

- (void)getNotificationCategoriesAsyncWithResolver:(UMPromiseResolveBlock)resolve reject:(UMPromiseRejectBlock)reject
{
  [[UNUserNotificationCenter currentNotificationCenter] getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *categories) {
    NSMutableArray* existingCategories = [NSMutableArray new];
    NSString *escapedExperienceId = [EXScopedNotificationsUtils escapedString:self->_experienceId];
    for (UNNotificationCategory *category in categories) {
      if ([category.identifier hasPrefix:escapedExperienceId]) {
        [existingCategories addObject:[self serializeCategory:category]];
      }
    }
    resolve(existingCategories);
  }];
}

- (void)setNotificationCategoryWithCategoryId:(NSString *)categoryId
                                      actions:(NSArray *)actions
                                      options:(NSDictionary *)options
                                      resolve:(UMPromiseResolveBlock)resolve
                                       reject:(UMPromiseRejectBlock)reject
{
  NSString *scopedCategoryIdentifier = [EXScopedNotificationsUtils scopedCategoryIdentifierWithId:categoryId
                                                                                    forExperience:_experienceId];
  [super setNotificationCategoryWithCategoryId:scopedCategoryIdentifier
                                       actions:actions
                                       options:options
                                       resolve:resolve
                                        reject:reject];
}

- (void)deleteNotificationCategoryWithCategoryId:(NSString *)categoryId
                                         resolve:(UMPromiseResolveBlock)resolve
                                          reject:(UMPromiseRejectBlock)reject
{
  NSString *scopedCategoryIdentifier = [EXScopedNotificationsUtils scopedCategoryIdentifierWithId:categoryId
                                                                                    forExperience:_experienceId];
  [super deleteNotificationCategoryWithCategoryId:scopedCategoryIdentifier
                                          resolve:resolve
                                           reject:reject];
}

- (NSMutableDictionary *)serializeCategory:(UNNotificationCategory *)category
{
  NSMutableDictionary* serializedCategory = [EXNotificationCategoriesModule serializeCategory:category];
  serializedCategory[@"identifier"] = [EXScopedNotificationsUtils unscopedCategoryIdentifierWithId:serializedCategory[@"identifier"]
                                                                                     forExperience:_experienceId];
  return serializedCategory;
}

#pragma mark - static method for migrating categories in both Expo Go and standalones. Added in SDK 41

+ (void)maybeMigrateLegacyCategoryIdentifiersForProject:(NSString *)experienceId isInExpoGo:(BOOL)isInExpoGo
{
  if (isInExpoGo) {
    // Changed scoping prefix in SDK 41 FROM "experienceId-" to ESCAPED "experienceId/"
    [EXScopedNotificationCategoryMigrator migrateCategoriesToNewScopingPrefix:experienceId];
  } else {
    // Used to prefix with "experienceId-" even in standalone apps in SDKs <= 40, so we need to unscope those
    [EXScopedNotificationCategoryMigrator migrateCategoriesToUnscopedIdentifiers:experienceId];
  }
}

@end
