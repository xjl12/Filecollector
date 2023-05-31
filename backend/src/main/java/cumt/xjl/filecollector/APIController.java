package cumt.xjl.filecollector;

import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.TreeSet;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.servlet.http.HttpServletResponse;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.URLEncoder;
import java.sql.Timestamp;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.system.ApplicationHome;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.rowset.SqlRowSet;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.util.FileSystemUtils;
import org.apache.commons.lang3.RandomStringUtils;

@CrossOrigin
@RestController
@RequestMapping("/api")
public class APIController {
    @Autowired
    JdbcTemplate db;

    @PostMapping("/requestNewCollector")
    public Map<String, Object> registerCollector(@RequestBody Map<String, Object> data) {
        Map<String, Object> res = new HashMap<String, Object>();
        res.put("success", false);
        Set<Integer> keys = new TreeSet<Integer>();
        SqlRowSet queryresult = db.queryForRowSet("SELECT sharekey FROM main;");
        while (queryresult.next()) {
            keys.add(queryresult.getInt("sharekey"));
        }
        int newkey;
        Random random = new Random();
        do {
            newkey = random.nextInt(1000000);
        } while (keys.contains(newkey));
        String storedirct = RandomStringUtils.randomAlphanumeric(16);
        String pass = RandomStringUtils.randomAlphanumeric(4);
        File dirct = getLocation(storedirct);
        dirct.mkdirs();
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, (int) data.get("days"));
        db.update("INSERT INTO main VALUES (? ,? ,?, ?,? ,?, ?, ?);", newkey, new Timestamp(cal.getTimeInMillis()),
                data.get("name"), data.get("filename"), storedirct, pass, data.get("num"), 0);
        res.replace("success", true);
        res.put("sharekey", String.format("%06d", newkey));
        res.put("password", pass);
        return res;
    }

    @GetMapping("/queryCollectorKey")
    public Map<String, Object> queryCollectorKey(@RequestParam int sharekey) {
        Map<String, Object> res = new HashMap<String, Object>();
        res.put("success", false);
        try {
            res = db.queryForMap("SELECT name,prompt FROM main WHERE sharekey = ? AND exptime > ?",
                    sharekey, new Timestamp(Calendar.getInstance().getTimeInMillis()));
        } catch (Exception e) {
            return res;
        }
        res.put("success", true);
        return res;
    }

    @GetMapping("/getCollectorState")
    public Map<String, Object> getCollectorState(@RequestParam int sharekey, @RequestParam String password) {
        Map<String, Object> res = new HashMap<String, Object>();
        res.put("success", false);
        try {
            res = db.queryForMap("SELECT name,num,received FROM main WHERE sharekey = ? AND password = ?",
                    sharekey, password);
            res.put("success", true);
        } catch (Exception e) {
            try {
                Thread.sleep(5000);
            } catch (InterruptedException e1) {
            }
            return res;
        }
        return res;
    }

    @PostMapping("/uploadColFile")
    @ResponseBody
    public Map<String, Object> uploadColFile(int sharekey,String name ,MultipartFile file) {
        Map<String, Object> res = new HashMap<String, Object>();
        res.put("success", false);
        try {
            String loc = (String) db.queryForMap("SELECT store FROM main WHERE sharekey = ? AND exptime > ?",
                    sharekey, new Timestamp(Calendar.getInstance().getTimeInMillis())).get("store");
            file.transferTo(new File(getLocation(loc),name));
            db.update("UPDATE main SET received = received + 1 WHERE sharekey = ?", sharekey);
            res.replace("success", true);
        } catch (Exception e) {
            return res;
        }
        return res;
    }

    @GetMapping("/downloadCollectorFiles")
    public void downloadCollector(@RequestParam int sharekey, @RequestParam String password,
            HttpServletResponse response) {
        try {
            Map<String, Object> data = db.queryForMap("SELECT name,store FROM main WHERE sharekey = ? AND password = ?",
                    sharekey, password);
            File srclist[] = getLocation((String) data.get("store")).listFiles();
            response.reset();
            if (srclist == null) {
                response.setStatus(500);
                return;
            }
            response.setContentType("application/zip");
            response.setHeader("Access-Control-Allow-Origin", "*");
            response.setHeader("Access-Control-Allow-Methods", "POST,GET,PUT,DELETE");
            response.setHeader("Access-Control-Max-Age", "3600");
            response.setHeader("Access-Control-Allow-Headers", "*");
            response.setHeader("Access-Control-Allow-Credentials", "true");
            response.addHeader("Content-Disposition",
                    "attachment;filename=" + URLEncoder.encode((String) data.get("name") + "_收集结果.zip", "UTF-8"));
            response.setContentType("application/octet-stream");
            ZipOutputStream zos = new ZipOutputStream(response.getOutputStream());
            byte buf[] = new byte[4096];
            InputStream is;
            for (File f : srclist) {
                if (f.isFile()) {
                    zos.putNextEntry(new ZipEntry(f.getName()));
                    is = new FileInputStream(f);
                    int tmp = 0;
                    while ((tmp = is.read(buf)) > 0) {
                        zos.write(buf, 0, tmp);
                    }
                    is.close();
                    zos.flush();
                    zos.closeEntry();
                }
            }
            zos.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @GetMapping("/deleteCollector")
    public Map<String, Object> deleteCollector(@RequestParam int sharekey, @RequestParam String password) {
        Map<String, Object> res = new HashMap<String, Object>();
        res.put("success", false);
        try {
            String loc = (String) db.queryForMap("SELECT store FROM main WHERE sharekey = ? AND password = ?",
                    sharekey, password).get("store");
            FileSystemUtils.deleteRecursively(getLocation(loc));
            db.update("DELETE FROM main WHERE sharekey = ?", sharekey);
            res.replace("success", true);
        } catch (Exception e) {
            try {
                Thread.sleep(5000);
            } catch (InterruptedException e1) {
            }
            return res;
        }
        return res;
    }

    File getLocation(String subloc) {
        ApplicationHome ah = new ApplicationHome(getClass());
        File file = new File(ah.getSource().getParentFile(),"/upload/"+subloc);
        return file;
    }
}