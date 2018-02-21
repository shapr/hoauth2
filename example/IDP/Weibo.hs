{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE QuasiQuotes   #-}

module IDP.Weibo where
import           Data.Aeson
import           Data.Aeson.Types
import           Data.Bifunctor
import           Data.Text.Lazy                    (Text)
import qualified Data.Text.Lazy                    as TL
import           GHC.Generics
import           Network.HTTP.Conduit
import           Network.OAuth.OAuth2
import qualified Network.OAuth.OAuth2.TokenRequest as TR
import           Types
import           URI.ByteString
import           URI.ByteString.QQ

-- TODO: http://open.weibo.com/wiki/2/users/show
data WeiboUser = WeiboUser { id         :: Integer
                           , name       :: Text
                           , screenName :: Text
                           } deriving (Show, Generic)

newtype WeiboUID = WeiboUID { uid :: Integer }
  deriving (Show, Generic)

instance FromJSON WeiboUID where
    parseJSON = genericParseJSON defaultOptions { fieldLabelModifier = camelTo2 '_' }
instance FromJSON WeiboUser where
    parseJSON = genericParseJSON defaultOptions { fieldLabelModifier = camelTo2 '_' }

userInfoUri :: URI
userInfoUri = [uri|https://api.weibo.com/2/account/get_uid.json|]

toLoginUser :: WeiboUID -> LoginUser
toLoginUser ouser = LoginUser { loginUserName = TL.pack $ show $ uid ouser }

-- fetch user info via
-- GET
-- access token in query param only
getUserInfo :: FromJSON a => Manager -> AccessToken -> IO (OAuth2Result a LoginUser)
getUserInfo mgr token = do
  re <- parseResponseJSON <$> authGetBS2 mgr token userInfoUri
  return (second toLoginUser re)

getAccessToken :: Manager
               -> OAuth2
               -> ExchangeToken
               -> IO (OAuth2Result TR.Errors OAuth2Token)
getAccessToken = fetchAccessToken
