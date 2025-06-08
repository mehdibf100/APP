class ApiConst{
  static const String baseUrl="https://pfe-project-backend-production.up.railway.app";

  static const String getAllUsersApi="$baseUrl/api/v1/user";
  static const String signInApi="$baseUrl/api/v1/auth/signin";
  static const String signUpApi="$baseUrl/api/v1/auth/signup";
  static const String createOrGetConversationApi="$baseUrl/api/v1/chat/conversation";
  static const String forgetPasswordApi="$baseUrl/api/v1/auth/forgot-password";
  static const String updatePasswordByEmailApi="$baseUrl/api/v1/auth/reset-password";
  static const String resetPasswordApi="$baseUrl/api/v1/auth/reset-password";
  static const String validCodeApi="$baseUrl/api/v1/auth/valid-code";
  static const String getUserByEmailApi="$baseUrl/api/v1/user";
  static const String updateUserByIdApi="$baseUrl/api/v1/user/update";
  static const String getALLOrdersApi="$baseUrl/api/v1/orders/all";
  static const String createPostClientApi="$baseUrl/api/v1/postClient/create";
  static const String createPostTransporterApi="$baseUrl/api/v1/postTransporter/create";
  static const String createDeliveryRequestCustomerApi="$baseUrl/api/v1/deliveryRequestCustomer/create";

  static const String createDeliveryRequestTransporterApi="$baseUrl/api/v1/deliveryRequestTransporter/create";
  static const String getDeliveryRequestTransporterByTransporterIdApi="$baseUrl/api/v1/deliveryRequestTransporter/transporter/";
  static const String createOrderApi="$baseUrl/api/v1/orders/create";
  static const String UpdateDeliveryRequestCustomerApi="$baseUrl/api/v1/deliveryRequestCustomer/update/";
  static const String filterPostClientApi="$baseUrl/api/v1/postClient/all";
  static const String filterPostTransporterApi="$baseUrl/api/v1/postTransporter/filter";
  static const String findPostTransporterByIdApi="$baseUrl/api/v1/postTransporter/id/";
  static const String findOrdersTransporterByIdApi="$baseUrl/api/v1/orders/transporter/";
  static const String findOrdersClientByIdApi="$baseUrl/api/v1/orders/client/";
  static const String updateOrderStatusByIdApi="$baseUrl/api/v1/orders/update/";
  static const String updateDeliveryRequestTransporterStatusByIdApi="$baseUrl/api/v1/deliveryRequestTransporter/update/";
  static const String deliveryRequestCustomerByClientIdApi="$baseUrl/api/v1/deliveryRequestCustomer/client/";
  static const String deliveryRequestCustomerByTransporterIdApi="$baseUrl/api/v1/deliveryRequestCustomer/transporter/";
  static const String getDeliveryRequestCustomerByIdApi="$baseUrl/api/v1/deliveryRequestCustomer/id/";
  static const String getDeliveryRequestTransporterByIdApi="$baseUrl/api/v1/deliveryRequestTransporter/id/";
  static const String getDeliveryRequestTransporterByCustomerIdApi="$baseUrl/api/v1/deliveryRequestTransporter/customer/";
  static const String acceptDeliveryRequestCustomerApi="$baseUrl/api/v1/deliveryRequestCustomer/accept/";
  static const String getClaimByUserIdApi="$baseUrl/api/v1/claim/userId/";
  static const String sendNotificationApi="$baseUrl/send-notification";

}