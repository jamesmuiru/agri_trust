
### **1. What is AgriConnect?**
**AgriConnect** is a digital marketplace application designed to bridge the gap between Kenyan farmers, consumers, and logistics providers. It eliminates middlemen by allowing farmers to sell fresh produce directly to buyers, ensuring fair prices for farmers and fresher, cheaper food for consumers. The platform also integrates a gig-economy model for delivery drivers to fulfill orders.

* **Core Value:** Transparency, Fair Pricing, and Efficient Logistics.
* **Target Audience:** Farmers (Sellers), Households/Businesses (Buyers), and Drivers (Logistics).
* **Key Tech:** Flutter (Mobile App), Firebase (Real-time Database), M-Pesa (Payments), and OpenStreetMap (Navigation).

---

### **2. How It Works (The Ecosystem)**
The app operates through three distinct roles, each with a specialized dashboard:

#### **A. For Farmers (The Suppliers)**
* **Listing Produce:** Farmers can easily list products (e.g., Cabbages, Tomatoes) by uploading photos, setting prices in **KES**, and defining available stock quantities.
* **Inventory Management:** The app tracks stock in real-time. Farmers can update quantities or mark items as "Out of Stock" directly from their dashboard.
* **Order Acceptance:** When a customer places an order, the farmer receives a notification. They must "Accept" the order to confirm they have the stock ready for pickup.
* **Revenue Tracking:** Farmers have an analytics dashboard showing total revenue and pending sales.

#### **B. For Customers (The Buyers)**
* **Smart Marketplace:** Customers browse a grid of fresh produce with transparent pricing and real-time stock levels. They can see exactly who the seller is (e.g., "Sold by: James").
* **Flexible Ordering:** Buyers can choose between **"Self Pickup"** (visit the farm) or **"Request Delivery"** (have it brought to them).
* **Secure Payments:**
    * **M-Pesa Express:** The app integrates Safaricom’s Daraja API. Users enter their phone number, and a PIN prompt appears automatically on their phone to pay.
    * **Pay on Delivery:** A manual option is available for users who prefer cash verification.
* **Transparency:** Customers can track their order status via a visual timeline (Placed $\rightarrow$ Accepted $\rightarrow$ On Way $\rightarrow$ Delivered) and download a professional **PDF Receipt** for every purchase.

#### **C. For Delivery Drivers (The Logistics)**
* **Job Discovery:** Drivers see a list of "New Opportunities"—orders that have been accepted by farmers but need delivery.
* **Navigation:** The app provides an interactive map showing the **Pickup Location** (Farm) and **Drop-off Location** (Customer) with distance calculation (e.g., "5.2 km away").
* **Communication:** Drivers have one-tap buttons to **Call** or **SMS** the customer or farmer to coordinate handover.
* **Completion:** Once delivered, the driver marks the order as "Delivered," completing the cycle and updating the status for everyone.

---

### **3. How to Access It**
Currently, AgriConnect is a functional prototype. Access is managed as follows:

* **Registration/Login:**
    * Users launch the app and reach the **Landing Page**.
    * They select their role (**Farmer**, **Customer**, or **Delivery**) during Sign Up.
    * Secure authentication (Email/Password) ensures data privacy.
* **Platform Availability:**
    * **Android:** The primary platform, fully optimized for mobile use with GPS and SMS capabilities.
    * **Web:** Accessible via browser for broader access (though M-Pesa automation is optimized for mobile).

**For Deployment (Future State):**
* The app is designed to be downloadable via the **Google Play Store**.
* Users will simply download "AgriConnect," register with their phone number, and start trading immediately.
