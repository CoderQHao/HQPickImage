//
//  HQImageCollectionViewController.swift
//  HQPickImage
//
//  Created by Enroute on 2017/11/10.
//  Copyright © 2017年 Qing's. All rights reserved.
//

import UIKit
import Photos

/// 相簿
struct HQImageAlbumItem {
    /// 相簿名称
    var title: String?
    /// 相簿内的资源
    var fetchResult: PHFetchResult<PHAsset>
}

private let kHQImageCollectionCellID = "kHQImageCollectionCellID"
private let kHQItemImageCellWidth = UIScreen.main.bounds.size.width / 4 - 1
private let kHQScale = UIScreen.main.scale
private let kHQScreenW = UIScreen.main.bounds.size.width
private let kHQScreenH = UIScreen.main.bounds.size.height
private let kHQNavH: CGFloat = 64
private let kHQBottomViewH: CGFloat = 44
private let kHQMargin: CGFloat = 10

class HQImageCollectionViewController: UIViewController {
    
    /// 相簿列表项集合
    fileprivate lazy var items = [HQImageAlbumItem]()
    /// 取得的资源结果
    fileprivate var assetsFetchResults: PHFetchResult<PHAsset>?
    /// 带缓存的图片管理对象
    fileprivate var imageManager = PHCachingImageManager()
    /// 根据单元格的尺寸计算我们需要的缩略图大小
    fileprivate var assetGridThumbnailSize = CGSize(width: kHQItemImageCellWidth * kHQScale, height: kHQItemImageCellWidth * kHQScale)
    /// 照片选择完毕后的回调
    fileprivate var completeHandler: ((_ images: [UIImage])->())?
    /// 样式
    fileprivate var style = HQPickImageStyle()
    
    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: kHQItemImageCellWidth, height: kHQItemImageCellWidth)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let frame = CGRect(x: 0, y: 0, width: kHQScreenW, height: kHQScreenH - kHQNavH - kHQBottomViewH)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.allowsMultipleSelection = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HQImageCollectionCell.self, forCellWithReuseIdentifier: kHQImageCollectionCellID)
        return collectionView
    }()
    
    fileprivate lazy var bottomView: UIView = {
        let bottomView = UIView()
        bottomView.frame = CGRect(x: 0, y: kHQScreenH - kHQBottomViewH - kHQNavH, width: kHQScreenW, height: kHQBottomViewH)
        return bottomView
    }()
    
    fileprivate lazy var completeBtn: HQImageCompleteButton = {
        let frame = CGRect(x: kHQScreenW - kHQMargin - 60, y: 9, width: 55, height: 26)
        let completeBtn = HQImageCompleteButton(frame: frame, style: style)
        completeBtn.addTarget(self, action: #selector(finishSelect), for: .touchUpInside)
        return completeBtn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全部照片"
        resetCachedAssets()
        setupUI()
        getAlbumResources()
    }
    
    // 重置缓存
    private func resetCachedAssets(){
        imageManager.stopCachingImagesForAllAssets()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        bottomView.addSubview(completeBtn)
        let btn = UIButton(type: .custom)
        btn.setTitle(style.cancelBtnTitle, for: .normal)
        btn.setTitleColor(style.cancelBtnColor, for: .normal)
        btn.titleLabel?.font = style.cancelBtnFont
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    // 取消按钮点击
    @objc private func cancelBtnClick() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // 完成按钮点击
    @objc private func finishSelect() {
        // 1.取出已选择的图片资源
        var images: [UIImage] = []
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            for indexPath in indexPaths {
                let asset = assetsFetchResults![indexPath.row - 1]
                imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) { (image, _) in
                    images.append(image!)
                }
            }
        }
        
        // 2.调用回调函数
        navigationController?.dismiss(animated: true, completion: {
            self.completeHandler?(images)
        })
    }
}

// MARK: - 获取相册资源
extension HQImageCollectionViewController {
    fileprivate func getAlbumResources() {
        PHPhotoLibrary.requestAuthorization { (status) in
            // 1.申请权限
            guard status == .authorized else { return }
            // 2.列出所有系统的智能相册
            let smartOptions = PHFetchOptions()
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: smartOptions)
            self.convertCollection(smartAlbums)
            // 3.列出所有用户创建的相册
            let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            /*** 'PHAssetCollection' 是 'PHCollection' 的子类 ***/
            self.convertCollection(userCollections as! PHFetchResult<PHAssetCollection>)
            // 4.相册按包含的照片数量排序(降序)
            self.items.sort { (item1, item2) -> Bool in
                return item1.fetchResult.count > item2.fetchResult.count
            }
            self.assetsFetchResults = self.items.first?.fetchResult
            // 5.异步加载表格数据,需要在主线程中调用'reloadData()'方法
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    /// 转化处理获取到的相簿
    private func convertCollection(_ phassetCollections: PHFetchResult<PHAssetCollection>) {
        for i in 0..<phassetCollections.count {
            // 1.获取出当前相簿内的图片
            let resultsOptions = PHFetchOptions()
            resultsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            resultsOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let phassetCollection = phassetCollections[i]
            let assetsFetchResult = PHAsset.fetchAssets(in: phassetCollection, options: resultsOptions)
            
            // 2. 没有图片的空相簿不显示
            if assetsFetchResult.count > 0 {
                let title = titleOfAlbumForChinese(title: phassetCollection.localizedTitle)
                items.append(HQImageAlbumItem(title: title, fetchResult: assetsFetchResult))
            }
        }
    }
    
    /// 由于系统返回的相册集名称为英文，需要将其转换为中文
    private func titleOfAlbumForChinese(title: String?) -> String? {
        guard let title = title else { return "" }
        switch title {
        case "Slo-mo":
            return "慢动作"
        case "Recently Added":
            return "最近添加"
        case "Favorites":
            return "个人收藏"
        case "Recently Deleted":
            return "最近删除"
        case "Videos":
            return "视频"
        case "All Photos":
            return "所有照片"
        case "Selfies":
            return "自拍"
        case "Screenshots":
            return "屏幕快照"
        case "Camera Roll":
            return "相机胶卷"
        default:
            return title
        }
    }
    
}

extension HQImageCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (assetsFetchResults?.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kHQImageCollectionCellID, for: indexPath) as! HQImageCollectionCell
        if indexPath.item == 0 {
            cell.imagView.image = UIImage(named: "HQPickImage.bundle/hq_camera")
            cell.selectedIcon.isHidden = true
        } else {
            cell.selectedIcon.isHidden = false
            let asset = assetsFetchResults![indexPath.row - 1]
            imageManager.requestImage(for: asset, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil) { (image, _) in
                cell.imagView.image = image
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? HQImageCollectionCell else { return }
        if indexPath.item == 0 {
            takePhoto()
        } else {
            let count = selectedCount()
            if count > style.maxSelected {
                collectionView.deselectItem(at: indexPath, animated: false)
                let title = "你最多只能选择\(style.maxSelected)张照片"
                let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title:"我知道了", style: .cancel, handler:nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                cell.playAnimate()
                completeBtn.num = count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let count = selectedCount()
        guard let cell = collectionView.cellForItem(at: indexPath) as? HQImageCollectionCell else { return }
        cell.playAnimate()
        completeBtn.num = count
    }
    
    /// 获取已选择个数
    fileprivate func selectedCount() -> Int {
        return collectionView.indexPathsForSelectedItems?.hqReject{ $0.item == 0 }.count ?? 0
    }
    
    /// 拍照
    fileprivate func takePhoto() {
        // 1.判断数据源是否可用
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        // 2.创建照片选择控制器
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self

        showDetailViewController(picker, sender: nil)
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension HQImageCollectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        // 1.获取图片
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        self.completeHandler?([image])
        // 2.退出选中照片控制器
        picker.dismiss(animated: true) {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
}


// MARK: - HQImageCollectionCell
class HQImageCollectionCell: UICollectionViewCell {
    var imagView = UIImageView()
    var selectedIcon = UIImageView(image: UIImage(named: "HQPickImage.bundle/hq_image_not_selected"))
    open override var isSelected: Bool {
        didSet {
            selectedIcon.image = isSelected ? UIImage(named: "HQPickImage.bundle/hq_image_selected") : UIImage(named: "HQPickImage.bundle/hq_image_not_selected")
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        imagView.contentMode = .scaleAspectFill
        imagView.clipsToBounds = true
        imagView.frame = self.bounds
        selectedIcon.frame = CGRect(x: imagView.frame.size.width - 30, y: 0, width: 30, height: 30)
        self.contentView.addSubview(imagView)
        self.contentView.addSubview(selectedIcon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 播放动画，是否选中的图标改变时使用
    func playAnimate() {
        // 图标先缩小，再放大
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                self.selectedIcon.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                self.selectedIcon.transform = CGAffineTransform.identity
            })
        }, completion: nil)
    }
}

class HQImageCompleteButton: UIButton {
    
    var num: Int = 0 {
        didSet {
            if num == 0 {
                self.isEnabled = false
                self.setTitle("完成", for: .normal)
                self.alpha = 0.5
            } else {
                self.isEnabled = true
                self.setTitle("完成(\(num))", for: .normal)
                self.alpha = 1.0
            }
        }
    }
    
    init(frame: CGRect, style: HQPickImageStyle) {
        super.init(frame: frame)
        self.setTitle("完成", for: .normal)
        self.alpha = 0.5
        self.isEnabled = false
        self.setTitleColor(style.completeBtnColor, for: .normal)
        self.backgroundColor = style.completeBtnBgColoe
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.layer.cornerRadius = 4.0
        self.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UIViewController {
    
    func presentHQImagePicker(style: HQPickImageStyle = HQPickImageStyle(),
                              completeHandler: ((_ images: [UIImage]) -> ())?) {
        let vc = HQImageCollectionViewController()
        vc.style = style
        vc.completeHandler = completeHandler
        let nav = UINavigationController(rootViewController: (vc))
        nav.view.backgroundColor = UIColor.white
        nav.navigationBar.setBackgroundImage(UIColor.hqCreateImageWithColor(style.narBarColor), for: .default)
        present(nav, animated: true, completion: nil)
    }
}

extension UIColor {
    class func hqCreateImageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(1.0), height: CGFloat(1.0))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let theImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return theImage!
    }
}

extension Array {
    /// 筛选出不满足条件的元素
    func hqReject(_ predicate: (Element) -> Bool) -> [Element] {
        return filter { !predicate($0) }
    }
}
