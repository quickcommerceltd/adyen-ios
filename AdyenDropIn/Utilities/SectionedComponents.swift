//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen

internal struct SectionedComponents {
    internal var paid: [PaymentComponent]
    internal var stored: [PaymentComponent]
    internal var regular: [PaymentComponent]
}
