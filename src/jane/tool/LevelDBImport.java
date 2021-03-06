package jane.tool;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Map.Entry;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import jane.core.Octets;
import jane.core.OctetsStream;
import jane.core.StorageLevelDB;

public final class LevelDBImport
{
	private static final Pattern      s_patHex  = Pattern.compile("\\\\x(..)");
	private static final Charset      s_cs88591 = Charset.forName("ISO-8859-1");
	private static final OctetsStream s_deleted = OctetsStream.wrap(Octets.EMPTY);

	private static OctetsStream str2Oct(String str)
	{
		String matchStr = "";
		try
		{
			Matcher mat = s_patHex.matcher(str);
			if(!mat.find()) return OctetsStream.wrap(str.getBytes(s_cs88591));
			StringBuffer sb = new StringBuffer(str.length());
			do
			{
				matchStr = mat.group(1);
				mat.appendReplacement(sb, Matcher.quoteReplacement(String.valueOf((char)(Integer.parseInt(matchStr, 16)))));
			}
			while(mat.find());
			return OctetsStream.wrap(mat.appendTail(sb).toString().getBytes(s_cs88591));
		}
		catch(RuntimeException e)
		{
			System.err.println("ERROR: parse failed: '" + matchStr + "' in '" + str + '\'');
			throw e;
		}
	}

	public static void main(String[] args) throws Exception
	{
		if(args.length < 1)
		{
			System.err.println("USAGE: java jane.tool.LevelDBImport <databasePath.ld> <dumpFile>");
			return;
		}
		String pathname = args[0].trim();
		String dumpname = args[1].trim();

		long t = System.currentTimeMillis();
		BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(dumpname), s_cs88591));
		System.err.println("INFO: opening " + pathname + " ...");
		long db = StorageLevelDB.leveldb_open(pathname, 0, 0, true);
		if(db == 0)
		{
			System.err.println("ERROR: leveldb_open failed");
			br.close();
			return;
		}

		System.err.println("INFO: importing db ...");
		Pattern patPut1 = Pattern.compile("put '(.*)' '(.*)'"); // the official leveldb log dump file
		Pattern patPut2 = Pattern.compile("'(.*)' @ \\d+ : val => '(.*)'"); // the official leveldb ldb dump file
		Pattern patPut3 = Pattern.compile("[\"(.*)\"]=\"(.*)\""); // LevelDBExport dump file
		Pattern patDel1 = Pattern.compile("del '(.*)'"); // the official leveldb log dump file
		Pattern patDel2 = Pattern.compile("'(.*)' @ \\d+ : del"); // the official leveldb ldb dump file
		ArrayList<Entry<Octets, OctetsStream>> buf = new ArrayList<Entry<Octets, OctetsStream>>(10000);
		long count = 0;
		String line;
		while((line = br.readLine()) != null)
		{
			Matcher mat;
			OctetsStream v;
			if((mat = patPut1.matcher(line)).find())
				v = str2Oct(mat.group(2));
			else if((mat = patPut2.matcher(line)).find())
				v = str2Oct(mat.group(2));
			else if((mat = patPut3.matcher(line)).find())
				v = str2Oct(mat.group(2));
			else if((mat = patDel1.matcher(line)).find())
				v = s_deleted;
			else if((mat = patDel2.matcher(line)).find())
				v = s_deleted;
			else
				continue;

			buf.add(new SimpleEntry<Octets, OctetsStream>(str2Oct(mat.group(1)), v));
			if(buf.size() >= 10000)
			{
				count += buf.size();
				StorageLevelDB.leveldb_write(db, buf.iterator());
				buf.clear();
			}
		}
		br.close();
		if(!buf.isEmpty())
		{
			count += buf.size();
			StorageLevelDB.leveldb_write(db, buf.iterator());
			buf.clear();
		}

		System.err.println("INFO: closing db ...");
		StorageLevelDB.leveldb_close(db);
		System.err.println("INFO: done! (count=" + count + ") (" + (System.currentTimeMillis() - t) + " ms)");
	}
}
