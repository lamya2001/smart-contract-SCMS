// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SupplyChainContract {
    // هيكل العنصر، يحتوي على اسم العنصر، الكمية، والخيارات كنص واحد
    struct Item {
        bytes32 itemName; // اسم المادة الخام كـ bytes32
        uint quantity; // الكمية المطلوبة
        string options; // الخيارات كنص واحد، مثلاً: "اللون أحمر، الحجم صغير"
    }

    // هيكل العقد
    struct Contract {
        uint purchaseOrderId; // معرف الطلب
        uint transportOrderId; // معرف التوصيل
        bytes32 sellerShortId; // shortId للبائع كـ bytes32
        bytes32 buyerShortId; // shortId للمشتري كـ bytes32
        bytes32 transporterId; // shortId للناقل كـ bytes32
        Item[] items; // العناصر المطلوبة في الطلب
        uint totalBuyerPayment; // المبلغ الذي دفعه المشتري للبائع
        uint totalTransportPayment; // المبلغ الذي دفعه البائع للناقل
        uint[] estimatedDeliveryTimes; // مصفوفة من طوابع زمنية تمثل تواريخ التوصيل المقدرة (بداية ونهاية)
        uint actualDeliveryTime; // الوقت الفعلي للتوصيل كـ uint (طابع زمني)
        uint purchaseOrderStatus; // حالة الطلب (0 = In Progress, 1 = Delivered)
        string sellerAddress; // عنوان البائع كـ bytes32
        string buyerAddress; // عنوان المشتري كـ bytes32
    }

    // خريطة لتخزين العقود باستخدام العنوان الفريد لكل عقد
    mapping(address => Contract) public contracts;

    // الصلاحيات
    address public companyAddress; // عنوان الشركة الذي يمتلك صلاحية التحديث

    // تحديد الشركة في البداية
    constructor() {
        companyAddress = msg.sender; // الشركة التي تمتلك الصلاحية لتحديث العقد
    }

    // Modifier للتحقق من أن الشخص هو الشركة
    modifier onlyCompany() {
        require(
            msg.sender == companyAddress,
            "You are not authorized to perform this action"
        );
        _;
    }

    // أحداث
    event ContractCreated(
        address indexed contractAddress,
        uint purchaseOrderId,
        uint transportOrderId,
        bytes32 sellerShortId,
        bytes32 buyerShortId,
        bytes32 transporterId
    );

    event ContractDelivered(
        address indexed contractAddress,
        uint actualDeliveryTime
    );

    // إضافة عقد جديد مع العناصر (فقط الشركة يمكنها إنشاء العقد)
    //address contractAddress, حذفته من اني استقبله
    function createContract(
        uint purchaseOrderId,
        uint transportOrderId,
        bytes32 sellerShortId,
        bytes32 buyerShortId,
        bytes32 transporterId,
        uint totalBuyerPayment,
        uint totalTransportPayment,
        uint[] memory estimatedDeliveryTimes,
        string memory sellerAddress,
        string memory buyerAddress,
        bytes32[] memory itemNames, // أسماء المواد الخام
        uint[] memory quantities, // الكميات
        string[] memory options // الخيارات كنص واحد لكل عنصر
    ) public onlyCompany {
        // توليد العنوان الفريد للعقد باستخدام address(this) أو msg.sender
        address contractAddress = address(this); // أو يمكن أن يكون msg.sender في حالة عقد متعدد الأطراف

        // إنشاء العقد الجديد
        Contract storage newContract = contracts[contractAddress];
        newContract.purchaseOrderId = purchaseOrderId;
        newContract.transportOrderId = transportOrderId;
        newContract.sellerShortId = sellerShortId;
        newContract.buyerShortId = buyerShortId;
        newContract.transporterId = transporterId;
        newContract.totalBuyerPayment = totalBuyerPayment;
        newContract.totalTransportPayment = totalTransportPayment;
        newContract.estimatedDeliveryTimes = estimatedDeliveryTimes;
        newContract.sellerAddress = sellerAddress;
        newContract.buyerAddress = buyerAddress;
        newContract.purchaseOrderStatus = 0; // حالة الطلب تبدأ بـ "In Progress"

        // إضافة العناصر والخيارات إلى العقد
        for (uint i = 0; i < itemNames.length; i++) {
            Item memory newItem;
            newItem.itemName = itemNames[i];
            newItem.quantity = quantities[i];
            newItem.options = options[i]; // تخزين الخيارات كنص واحد

            // إضافة العنصر المكتمل إلى العقد
            newContract.items.push(newItem);
        }

        // استدعاء حدث ContractCreated بعد إنشاء العقد
        emit ContractCreated(
            contractAddress,
            purchaseOrderId,
            transportOrderId,
            sellerShortId,
            buyerShortId,
            transporterId
        );
    }

    // تحديث حالة الطلب إلى "تم التوصيل" وتعيين التاريخ الفعلي (فقط الشركة يمكنها تحديث الحالة)
    function markContractAsDelivered(
        address contractAddress,
        uint actualDeliveryTime
    ) public onlyCompany {
        Contract storage existingContract = contracts[contractAddress];
        existingContract.purchaseOrderStatus = 1; // تحديث الحالة إلى "Delivered"
        existingContract.actualDeliveryTime = actualDeliveryTime; // تعيين التاريخ الفعلي للتوصيل

        // استدعاء حدث ContractDelivered بعد تحديث الحالة
        emit ContractDelivered(contractAddress, actualDeliveryTime);
    }

    // استرجاع تفاصيل العقد حسب العنوان
    function getContract(
        address contractAddress
    ) public view returns (Contract memory) {
        return contracts[contractAddress];
    }

    // استرجاع تفاصيل العنصر من عقد معين
    function getItemFromContract(
        address contractAddress,
        uint itemIndex
    ) public view returns (Item memory) {
        return contracts[contractAddress].items[itemIndex];
    }
}
